-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Gép: localhost:3306
-- Létrehozás ideje: 2026. Nov 17. 09:54
-- Kiszolgáló verziója: 5.7.24
-- PHP verzió: 8.3.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Adatbázis: `fittrack`
--
CREATE DATABASE IF NOT EXISTS `fittrack` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `fittrack`;

DELIMITER $$
--
-- Eljárások
--
DROP PROCEDURE IF EXISTS `sp_ChangePassword`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ChangePassword` (IN `p_user_id` INT, IN `p_new_password_hash` VARCHAR(255))   BEGIN
	UPDATE users
    SET password_hash = p_new_password_hash,
    	updated_at = CURRENT_TIMESTAMP
    WHERE id = p_user_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_GetAllCategories`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetAllCategories` ()   BEGIN
    SELECT id, name, icon 
    FROM categories 
    WHERE is_deleted = 0 
    ORDER BY name ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_GetExerciseById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetExerciseById` (IN `p_exercise_id` INT)   BEGIN
    SELECT id, category_id, created_by_user_id, name, description, is_custom 
    FROM exercises 
    WHERE id = p_exercise_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_GetExerciseMaxWeights`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetExerciseMaxWeights` (IN `p_user_id` INT, IN `p_exercise_id` INT)   BEGIN
    SELECT 
        w.workout_date,
        MAX(es.weight_kg) AS max_weight_kg
    FROM workouts w
    JOIN workout_exercises we ON w.id = we.workout_id
    JOIN exercise_sets es ON we.id = es.workout_exercise_id
    WHERE w.user_id = p_user_id 
      AND we.exercise_id = p_exercise_id
      AND w.is_deleted = 0 
      AND we.is_deleted = 0 
      AND es.is_deleted = 0
      AND es.completed = 1
    GROUP BY w.workout_date, w.id
    ORDER BY w.workout_date ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_GetExerciseSetById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetExerciseSetById` (IN `p_set_id` INT)   BEGIN
    SELECT id, workout_exercise_id, set_number, weight_kg, reps, rest_time_seconds, completed
    FROM exercise_sets
    WHERE id = p_set_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_GetUserByAuthCode`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetUserByAuthCode` (IN `p_auth_code` VARCHAR(255))   BEGIN
    SELECT id, username, email, created_at 
    FROM users 
    WHERE authentication_code = p_auth_code 
      AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_GetUserByEmail`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetUserByEmail` (IN `p_email` VARCHAR(255))   BEGIN
    SELECT id, username, email, password_hash, created_at 
    FROM users 
    WHERE email = p_email AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_GetUserProfile`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetUserProfile` (IN `p_user_id` INT)   BEGIN
    SELECT id, user_id, height_cm, target_weight_kg, unit_system, theme
    FROM user_profiles
    WHERE user_id = p_user_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_GetUserStatById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetUserStatById` (IN `p_stat_id` INT)   BEGIN
    SELECT id, user_id, recorded_at, weight_kg, body_fat_percentage
    FROM user_stats
    WHERE id = p_stat_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_GetUserWeightProgress`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetUserWeightProgress` (IN `p_user_id` INT, IN `p_start_date` DATE, IN `p_end_date` DATE)   BEGIN
    SELECT 
        recorded_at, 
        weight_kg, 
        body_fat_percentage
    FROM user_stats
    WHERE user_id = p_user_id 
      AND recorded_at BETWEEN p_start_date AND p_end_date
      AND is_deleted = 0
    ORDER BY recorded_at ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_GetUserWorkouts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetUserWorkouts` (IN `p_user_id` INT)   BEGIN
    SELECT id, title, workout_date, duration_minutes, notes, created_at
    FROM workouts
    WHERE user_id = p_user_id AND is_deleted = 0
    ORDER BY workout_date DESC;
END$$

DROP PROCEDURE IF EXISTS `sp_GetWorkoutDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetWorkoutDetails` (IN `p_workout_id` INT)   BEGIN
    -- Edzés adatai
    SELECT id, title, workout_date, duration_minutes, notes 
    FROM workouts 
    WHERE id = p_workout_id AND is_deleted = 0;

    -- Edzéshez tartozó gyakorlatok és sorozatok
    SELECT 
        we.id AS workout_exercise_id,
        e.name AS exercise_name,
        c.name AS category_name,
        we.order_index,
        es.set_number,
        es.weight_kg,
        es.reps,
        es.completed
    FROM workout_exercises we
    JOIN exercises e ON we.exercise_id = e.id
    JOIN categories c ON e.category_id = c.id
    JOIN exercise_sets es ON we.id = es.workout_exercise_id
    WHERE we.workout_id = p_workout_id 
      AND we.is_deleted = 0 
      AND es.is_deleted = 0
    ORDER BY we.order_index ASC, es.set_number ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_RegisterUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_RegisterUser` (IN `p_username` VARCHAR(50), IN `p_email` VARCHAR(255), IN `p_password_hash` VARCHAR(255))   BEGIN
    DECLARE user_exists INT DEFAULT 0;
    DECLARE new_user_id INT;

    SELECT COUNT(*) INTO user_exists 
    FROM users 
    WHERE email = p_email AND is_deleted = 0;

    IF user_exists > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ez az email-cím már regisztrálva van!';
    ELSE
        INSERT INTO users (username, email, password_hash)
        VALUES (p_username, p_email, p_password_hash);
        
        SET new_user_id = LAST_INSERT_ID();
        
        INSERT INTO user_profiles (user_id, unit_system, theme)
        VALUES (new_user_id, 'metric', 'dark');
        
        SELECT id, username, email, created_at 
        FROM users 
        WHERE id = new_user_id;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `sp_SaveCompleteWorkout`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_SaveCompleteWorkout` (IN `p_user_id` INT, IN `p_title` VARCHAR(100), IN `p_workout_date` DATETIME, IN `p_duration_minutes` INT, IN `p_notes` TEXT, OUT `p_workout_id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hiba történt az edzés mentése során!';
    END;

    START TRANSACTION;

    INSERT INTO workouts (user_id, title, workout_date, duration_minutes, notes)
    VALUES (p_user_id, p_title, p_workout_date, p_duration_minutes, p_notes);

    SET p_workout_id = LAST_INSERT_ID();

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `sp_SoftDeleteUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_SoftDeleteUser` (IN `p_user_id` INT)   BEGIN
    UPDATE users 
    SET is_deleted = 1, 
        deleted_at = CURRENT_TIMESTAMP 
    WHERE id = p_user_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateCategory`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateCategory` (IN `p_category_id` INT, IN `p_name` VARCHAR(50), IN `p_icon` VARCHAR(50))   BEGIN
    UPDATE categories
    SET name = p_name,
        icon = p_icon,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_category_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateExercise`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateExercise` (IN `p_exercise_id` INT, IN `p_name` VARCHAR(100), IN `p_description` TEXT, IN `p_category_id` INT)   BEGIN
    UPDATE exercises
    SET name = p_name,
        description = p_description,
        category_id = p_category_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_exercise_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateExerciseSet`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateExerciseSet` (IN `p_set_id` INT, IN `p_weight_kg` DECIMAL(5,2), IN `p_reps` INT, IN `p_rest_time_seconds` INT, IN `p_completed` TINYINT(1))   BEGIN
    UPDATE exercise_sets
    SET weight_kg = p_weight_kg,
        reps = p_reps,
        rest_time_seconds = p_rest_time_seconds,
        completed = p_completed,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_set_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateUser` (IN `p_user_id` INT, IN `p_username` VARCHAR(50), IN `p_email` VARCHAR(255))   BEGIN
    DECLARE email_owner INT DEFAULT 0;

    SELECT COUNT(*) INTO email_owner 
    FROM users 
    WHERE email = p_email AND id != p_user_id AND is_deleted = 0;

    IF email_owner > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Hiba: Ez az email-cím már egy másik fiókhoz tartozik!';
    ELSE
        UPDATE users
        SET username = p_username,
            email = p_email,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_user_id AND is_deleted = 0;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateUserProfile`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateUserProfile` (IN `p_user_id` INT, IN `p_height_cm` INT, IN `p_target_weight_kg` DECIMAL(5,2), IN `p_unit_system` ENUM('metric','imperial'), IN `p_theme` VARCHAR(20))   BEGIN
    UPDATE user_profiles
    SET height_cm = p_height_cm,
        target_weight_kg = p_target_weight_kg,
        unit_system = p_unit_system,
        theme = p_theme,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateUserStat`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateUserStat` (IN `p_stat_id` INT, IN `p_recorded_at` DATE, IN `p_weight_kg` DECIMAL(5,2), IN `p_body_fat_percentage` DECIMAL(4,2))   BEGIN
    UPDATE user_stats
    SET recorded_at = p_recorded_at,
        weight_kg = p_weight_kg,
        body_fat_percentage = p_body_fat_percentage,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_stat_id AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateWorkout`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateWorkout` (IN `p_workout_id` INT, IN `p_user_id` INT, IN `p_title` VARCHAR(100), IN `p_workout_date` DATETIME, IN `p_duration_minutes` INT, IN `p_notes` TEXT)   BEGIN
    UPDATE workouts
    SET title = p_title,
        workout_date = p_workout_date,
        duration_minutes = p_duration_minutes,
        notes = p_notes,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_workout_id 
      AND user_id = p_user_id 
      AND is_deleted = 0;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateWorkoutDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateWorkoutDetails` (IN `p_workout_id` INT, IN `p_title` VARCHAR(100), IN `p_workout_date` DATETIME, IN `p_duration_minutes` INT, IN `p_notes` TEXT)   BEGIN
    UPDATE workouts
    SET title = p_title,
        workout_date = p_workout_date,
        duration_minutes = p_duration_minutes,
        notes = p_notes,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_workout_id AND is_deleted = 0;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `categories`
--

DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `categories`
--

INSERT INTO `categories` (`id`, `name`, `icon`, `created_at`, `updated_at`, `deleted_at`, `is_deleted`) VALUES
(1, 'Mell', 'chest-icon', '2026-10-01 08:42:03', '2026-10-01 08:42:03', NULL, 0),
(2, 'Hát', 'back-icon', '2026-10-01 08:42:03', '2026-10-01 08:42:03', NULL, 0),
(3, 'Láb', 'leg-icon', '2026-10-01 08:42:03', '2026-10-01 08:42:03', NULL, 0),
(4, 'Kar', 'arm-icon', '2026-10-01 08:42:03', '2026-10-01 08:42:03', NULL, 0),
(5, 'Váll', 'shoulder-icon', '2026-10-01 08:42:03', '2026-10-01 08:42:03', NULL, 0),
(6, 'Has', 'abs-icon', '2026-10-01 08:42:03', '2026-10-01 08:42:03', NULL, 0),
(7, 'Kardió', 'cardio-icon', '2026-10-01 08:42:03', '2026-10-01 08:42:03', NULL, 0);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `exercises`
--

DROP TABLE IF EXISTS `exercises`;
CREATE TABLE `exercises` (
  `id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `created_by_user_id` int(11) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `description` text,
  `is_custom` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `exercise_sets`
--

DROP TABLE IF EXISTS `exercise_sets`;
CREATE TABLE `exercise_sets` (
  `id` int(11) NOT NULL,
  `workout_exercise_id` int(11) NOT NULL,
  `set_number` int(11) NOT NULL,
  `weight_kg` decimal(5,2) NOT NULL DEFAULT '0.00',
  `reps` int(11) NOT NULL DEFAULT '0',
  `rest_time_seconds` int(11) DEFAULT NULL,
  `completed` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `authentication_code` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Eseményindítók `users`
--
DROP TRIGGER IF EXISTS `trg_BeforeUserInsert`;
DELIMITER $$
CREATE TRIGGER `trg_BeforeUserInsert` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
    IF EXISTS (
        SELECT 1 FROM users 
        WHERE email = NEW.email AND is_deleted = 0
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Hiba: Ez az email-cím már használatban van egy aktív fióknál!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `user_profiles`
--

DROP TABLE IF EXISTS `user_profiles`;
CREATE TABLE `user_profiles` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `height_cm` int(11) DEFAULT NULL,
  `target_weight_kg` decimal(5,2) DEFAULT NULL,
  `unit_system` enum('metric','imperial') NOT NULL DEFAULT 'metric',
  `theme` varchar(20) NOT NULL DEFAULT 'dark',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `user_stats`
--

DROP TABLE IF EXISTS `user_stats`;
CREATE TABLE `user_stats` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `recorded_at` date NOT NULL,
  `weight_kg` decimal(5,2) NOT NULL,
  `body_fat_percentage` decimal(4,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `workouts`
--

DROP TABLE IF EXISTS `workouts`;
CREATE TABLE `workouts` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `workout_date` datetime NOT NULL,
  `duration_minutes` int(11) DEFAULT NULL,
  `notes` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `workout_exercises`
--

DROP TABLE IF EXISTS `workout_exercises`;
CREATE TABLE `workout_exercises` (
  `id` int(11) NOT NULL,
  `workout_id` int(11) NOT NULL,
  `exercise_id` int(11) NOT NULL,
  `order_index` int(11) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexek a kiírt táblákhoz
--

--
-- A tábla indexei `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- A tábla indexei `exercises`
--
ALTER TABLE `exercises`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_exercises_category` (`category_id`),
  ADD KEY `idx_exercises_user` (`created_by_user_id`);

--
-- A tábla indexei `exercise_sets`
--
ALTER TABLE `exercise_sets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_sets_workout_exercise` (`workout_exercise_id`);

--
-- A tábla indexei `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- A tábla indexei `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- A tábla indexei `user_stats`
--
ALTER TABLE `user_stats`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_stats_user_date` (`user_id`,`recorded_at`);

--
-- A tábla indexei `workouts`
--
ALTER TABLE `workouts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_workouts_user` (`user_id`),
  ADD KEY `idx_workouts_date` (`workout_date`);

--
-- A tábla indexei `workout_exercises`
--
ALTER TABLE `workout_exercises`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_we_workout` (`workout_id`),
  ADD KEY `idx_we_exercise` (`exercise_id`);

--
-- A kiírt táblák AUTO_INCREMENT értéke
--

--
-- AUTO_INCREMENT a táblához `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT a táblához `exercises`
--
ALTER TABLE `exercises`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `exercise_sets`
--
ALTER TABLE `exercise_sets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `user_profiles`
--
ALTER TABLE `user_profiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `user_stats`
--
ALTER TABLE `user_stats`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `workouts`
--
ALTER TABLE `workouts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `workout_exercises`
--
ALTER TABLE `workout_exercises`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Megkötések a kiírt táblákhoz
--

--
-- Megkötések a táblához `exercises`
--
ALTER TABLE `exercises`
  ADD CONSTRAINT `exercises_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `exercises_ibfk_2` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Megkötések a táblához `exercise_sets`
--
ALTER TABLE `exercise_sets`
  ADD CONSTRAINT `exercise_sets_ibfk_1` FOREIGN KEY (`workout_exercise_id`) REFERENCES `workout_exercises` (`id`) ON DELETE CASCADE;

--
-- Megkötések a táblához `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD CONSTRAINT `user_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Megkötések a táblához `user_stats`
--
ALTER TABLE `user_stats`
  ADD CONSTRAINT `user_stats_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Megkötések a táblához `workouts`
--
ALTER TABLE `workouts`
  ADD CONSTRAINT `workouts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Megkötések a táblához `workout_exercises`
--
ALTER TABLE `workout_exercises`
  ADD CONSTRAINT `workout_exercises_ibfk_1` FOREIGN KEY (`workout_id`) REFERENCES `workouts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `workout_exercises_ibfk_2` FOREIGN KEY (`exercise_id`) REFERENCES `exercises` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
