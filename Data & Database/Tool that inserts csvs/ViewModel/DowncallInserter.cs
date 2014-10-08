using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;

namespace InheritanceInsertion.ViewModel
{
    internal class DowncallInserter : DataInserter
    {
        private readonly int _projectId;
        private readonly DataTable _table;

        public DowncallInserter(int projectId)
        {
            _projectId = projectId;
            _table = new DataTable();
            _table.Columns.Add("ProjectId"  , typeof (int));
            _table.Columns.Add("FromType"   , typeof (int));
            _table.Columns.Add("ToType", typeof(int));
            _table.Columns.Add("Direct", typeof(bool));
            _table.Columns.Add("FromMethod" , typeof(string));
            _table.Columns.Add("ToMethod"   , typeof(string));
            _table.Columns.Add("Declaration", typeof (string));
        }

        public async Task SaveAsync()
        {
            await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var adapter = GetAdapterForInsert(conn, "select * from Downcall");
                    adapter.Update(_table);
                }
            });
        }

        public void AddItem(int fromType, int toType, bool direct, string fromMethod, string toMethod, string declaration)
        {
            DataRow row = _table.NewRow();
            row["ProjectId"] = _projectId;
            row["FromType"] = fromType;
            row["Direct"] = direct;
            row["ToType"] = toType;
            row["FromMethod"] = fromMethod;
            row["ToMethod"] = toMethod;
            row["Declaration"] = declaration;
            _table.Rows.Add(row);
        }
    }
}