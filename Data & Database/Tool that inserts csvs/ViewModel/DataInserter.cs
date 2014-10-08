using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InheritanceInsertion.ViewModel
{
    public abstract class DataInserter
    {
        protected async Task<SqlConnection> CreateConnectionAsync()
        {
            var connection = new SqlConnection("Data Source=.;Initial Catalog=MasterThesis;Integrated Security=True");
            await connection.OpenAsync();
            return connection;
        }

        protected SqlDataAdapter GetAdapterForInsert(SqlConnection connection, string selectCommand)
        {
            var adapter = new SqlDataAdapter(selectCommand, connection);
            var builder = new SqlCommandBuilder(adapter);
            adapter.InsertCommand = builder.GetInsertCommand();
            adapter.InsertCommand.CommandTimeout = 600000;
            return adapter;
        }
    }

    public class ProjectInserter : DataInserter
    {
        public async Task<int> InsertProjectAsync(string name, string language, int linesOfCode, int linesOfComment, int linesOfBlank, string sourceCodeType)
        {
            return await Task.Run(async () =>
            {
                const string commandText = "insert into Project (Language, Name, LinesOfCode, LinesOfComment, LinesOfBlank, ProjectType) values (@Language, @Name, @LinesOfCode, @LinesOfComment, @LinesOfBlank, @ProjectType) " +
                                           "select convert(int, scope_identity())";

                using (var conn = await CreateConnectionAsync())
                {
                    var command = conn.CreateCommand();
                    command.CommandText = commandText;
                    command.Parameters.AddWithValue("@Name", name);
                    command.Parameters.AddWithValue("@Language", language);
                    command.Parameters.AddWithValue("@LinesOfCode", linesOfCode);
                    command.Parameters.AddWithValue("@LinesOfComment", linesOfComment);
                    command.Parameters.AddWithValue("@LinesOfBlank", linesOfBlank);
                    command.Parameters.AddWithValue("@ProjectType", sourceCodeType);
                    return (int)await command.ExecuteScalarAsync();
                }
            });
        }
    }

    public class TypeData : DataInserter
    {
        public async Task<Dictionary<string, int>> CreateTypeDictionary(int projectId, List<string> typeNames, Dictionary<string, bool> systemtypes)
        {
            return await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var table = new DataTable();
                    table.Columns.Add("TypeId", typeof(int));
                    table.Columns.Add("ProjectId", typeof(int));
                    table.Columns.Add("TypeLocation", typeof(string));
                    table.Columns.Add("IsOwnCode", typeof(bool));
                    var adapter = new SqlDataAdapter(new SqlCommand("select * from [Type]", conn));
                    var builder = new SqlCommandBuilder(adapter);
                    builder.GetInsertCommand();
                    adapter.Update(table);
                    foreach (var typeName in typeNames)
                    {
                        var row = table.NewRow();
                        row["ProjectId"] = projectId;
                        row["TypeLocation"] = typeName;
                        row["IsOwnCode"] = systemtypes[typeName];
                        table.Rows.Add(row);

                    }
                    adapter.Update(table);

                    var command = conn.CreateCommand();
                    command.CommandText = "select TypeId, TypeLocation from [Type] where projectid = @ProjectId";
                    command.Parameters.AddWithValue("@ProjectId", projectId);
                    var reader = await command.ExecuteReaderAsync();
                    var result = new Dictionary<string, int>();
                    while (reader.Read())
                    {
                        result.Add(reader.GetString(1), reader.GetInt32(0));
                    }
                    return result;
                }
            });
        }
    }
}
