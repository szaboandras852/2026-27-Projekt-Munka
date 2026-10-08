using Microsoft.EntityFrameworkCore;

namespace TodoApi.Models;

public class GymContext : DbContext
{
    public GymContext(DbContextOptions<GymContext> options )
        
    {
            
    }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        var connectionString = Environment.GetEnvironmentVariable("DefaultConnection")
            ?? throw new InvalidOperationException("Database connection string is not set.");
        options.UseSqlServer(connectionString);
    }
    public DbSet<UserItem> UserItems { get; set; } = null!;
}