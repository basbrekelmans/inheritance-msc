using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InheritanceInsertion.ViewModel
{
    static class ProjectInfo
    {
        public static ISet<string> ExistingProjectNames()
        {
            var items = new HashSet<string>();
            using (var connection = new SqlConnection("Data Source=.;Integrated Security=true;Initial Catalog=MasterThesis;"))
            {
                using (var cmd = connection.CreateCommand())
                {
                    cmd.CommandText = "select distinct Name from Project";
                    connection.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            items.Add(reader.GetString(0));
                        }
                    }
                }
            }
            return items;
        }
    }
}
