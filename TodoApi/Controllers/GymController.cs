using Microsoft.AspNetCore.Mvc;
using TodoApi.Models;

namespace TodoApi.Controllers;

[ApiController]
[Route("/api/AAAAAAAA")]
public class GymController : ControllerBase
{
    private readonly GymContext gymContext;

    public GymController( GymContext gymContext)
    {
        this.gymContext = gymContext;
    }
    private static readonly string[] Summaries =
    [
        "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
    ];

   /* [HttpGet(Name = "GetUsers")]
    public IEnumerable<Models.UserItem> Get()
    {
        
        return Enumerable.Range(1, 1).Select(index => new Models.UserItem
        {
            Id = 1,
            username = "TEST",
            email = "Testmail@MAIL.com"
        })
        .ToArray();
    }*/
//https://dev.to/esdanielgomez/rest-api-with-aspnet-and-mysql-5c6h
    [HttpGet("GetUsers")]
public async Task<ActionResult<List<UserItem>>> Get()
{
    var List = await gymContext.User.Select(
        s => new UserItem
        {
            Id = s.Id,
            FirstName = s.FirstName,
            LastName = s.LastName,
            Username = s.Username,
            Password = s.Password,
            EnrollmentDate = s.EnrollmentDate
        }
    ).ToListAsync();

    if (List.Count < 0)
    {
        return NotFound();
    }
    else
    {
        return List;
    }
}
}
