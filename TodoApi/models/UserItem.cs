using NuGet.Packaging.Signing;

namespace TodoApi.Models;

public class UserItem
{
    public long Id { get; set; }
    public string? username { get; set; }
    public string? email { get; set; }
    public string?  password_hash { get; set; }
    public Timestamp created_at { get; set; }
    public Timestamp updated_at { get; set; }
    public Timestamp deleted_at { get; set; }
    public bool is_deleted { get; set; }

}