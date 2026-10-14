using Microsoft.EntityFrameworkCore;

namespace TodoApi.Models;

public class GymContext : DbContext
{
    public GymContext(DbContextOptions<GymContext> options )
    : base(options)
        
    {
            
    }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        //var connectionString = Environment.GetEnvironmentVariable("DefaultConnection")
        //    ?? throw new InvalidOperationException("Database connection string is not set.");
        String connectionString = "server=localhost;port=3306;user=root;password=root;database=fittrack;";
        options.UseSqlServer(connectionString);
    }
    public DbSet<UserItem> UserItems { get; set; } = null!;

    public async Task<List<UserItem>> GetCompanies()
{
     return (from b in UserItems orderby b.username select b).ToList();
     
}
}