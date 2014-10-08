using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InheritanceInsertion.ViewModel
{
    class SuperInserter : DataInserter
    {
        private readonly int _projectId;
        private DataTable _table;

        public SuperInserter(int projectId)
        {
            _projectId = projectId;
            _table = new DataTable();
            _table.Columns.Add("ProjectId", typeof (int));
            _table.Columns.Add("FromType", typeof(int));
            _table.Columns.Add("ToType", typeof(int));
            _table.Columns.Add("Declaration", typeof(string));

        }

        public async Task SaveAsync()
        {
            await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var adapter = GetAdapterForInsert(conn, "select * from Super");
                    adapter.Update(_table);
                }
            });
        }

        public void AddItem(string declaration, int fromType, int toType)
        {
            var row = _table.NewRow();
            row["ProjectId"] = _projectId;
            row["FromType"] = fromType;
            row["ToType"] = toType;
            row["Declaration"] = declaration;
            _table.Rows.Add(row);
        }
    }
}
