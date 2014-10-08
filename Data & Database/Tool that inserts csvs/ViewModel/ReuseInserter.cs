using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InheritanceInsertion.ViewModel
{
    public class InternalReuseInserter : ReuseInserter
    {
        public InternalReuseInserter(int projectId) : base(projectId, "InternalReuse")
        {
        }
    }
    public class ExternalReuseInserter : ReuseInserter
    {
        public ExternalReuseInserter(int projectId)
            : base(projectId, "ExternalReuse")
        {
        }
    }

    public class ReuseInserter : DataInserter
    {     private readonly int _projectId;
        private readonly string _tableName;
        private readonly DataTable _table;

        public ReuseInserter(int projectId, string tableName)
        {
            _projectId = projectId;
            _tableName = tableName;
            _table = new DataTable();
            _table.Columns.Add("InternalReuseId", typeof (long));
            _table.Columns.Add("ProjectId", typeof (int));
            _table.Columns.Add("FromType", typeof(int));
            _table.Columns.Add("ToType", typeof(int));
            _table.Columns.Add("Direct", typeof(bool));
            _table.Columns.Add("ReuseType", typeof(string));
            _table.Columns.Add("From", typeof(string));
            _table.Columns.Add("To", typeof(string));

        }

        public async Task SaveAsync()
        {
            await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var adapter = GetAdapterForInsert(conn, "select * from " + _tableName);
                    adapter.Update(_table);
                }
            });
        }

        public void AddItem(bool direct, string from, string to, string reuseType, int fromType, int toType)
        {
            var row = _table.NewRow();
            row["ProjectId"] = _projectId;
            row["FromType"] = fromType;
            row["ToType"] = toType;
            row["Direct"] = direct;
            row["ReuseType"] = reuseType;
            row["From"] = from;
            row["To"] = to;
            _table.Rows.Add(row);
        }
    }
}
