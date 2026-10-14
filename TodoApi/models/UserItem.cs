using NuGet.Packaging.Signing;

namespace TodoApi.Models;

public class UserItem
{
    public long Id { get; set; }
    public string? username { get; set; }
    public string? email { get; set; }
    public string?  password_hash { get; set; }
    public DateTime created_at { get; set; }
    public DateTime updated_at { get; set; }
    public DateTime deleted_at { get; set; }
    public bool is_deleted { get; set; }

}