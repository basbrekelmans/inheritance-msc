using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;

namespace InheritanceInsertion.ViewModel
{
    internal class DynamicInserter : DataInserter
    {
        private readonly int _projectId;
        private readonly DataTable _table;

        public DynamicInserter(int projectId)
        {
            _projectId = projectId;
            _table = new DataTable();
            _table.Columns.Add("ProjectId", typeof(int));
            _table.Columns.Add("StaticOccurrences", typeof(int));
            _table.Columns.Add("DynamicOccurrences", typeof(int));
            _table.Columns.Add("VarCount", typeof(int));
            _table.Columns.Add("NonVarCount", typeof(int));
        }

        public async Task SaveAsync()
        {
            await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var adapter = GetAdapterForInsert(conn, "select * from DynamicUse");
                    adapter.Update(_table);
                }
            });
        }

        public void AddItem(int staticuse, int dynamicUse, int varCount, int nonVarCount)
        {
            DataRow row = _table.NewRow();
            row["ProjectId"] = _projectId;
            row["StaticOccurrences"] = staticuse;
            row["DynamicOccurrences"] = dynamicUse;
            row["VarCount"] = varCount;
            row["NonVarCount"] = nonVarCount;
            _table.Rows.Add(row);
        }
    }

    internal class SubtypeInserter : DataInserter
    {
        private readonly int _projectId;
        private readonly DataTable _table;

        public SubtypeInserter(int projectId)
        {
            _projectId = projectId;
            _table = new DataTable();
            _table.Columns.Add("SubtypeId", typeof (long));
            _table.Columns.Add("ProjectId", typeof (int));
            _table.Columns.Add("FromType", typeof (int));
            _table.Columns.Add("ToType", typeof (int));
            _table.Columns.Add("Direct", typeof (bool));
            _table.Columns.Add("SubtypeKind", typeof (string));
            _table.Columns.Add("Source", typeof(string));
            _table.Columns.Add("Omitted", typeof(bool));
        }

        public async Task SaveAsync()
        {
            await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var adapter = GetAdapterForInsert(conn, "select * from Subtype");
                    adapter.Update(_table);
                }
            });
        }

        public void AddItem(int fromType, int toType, bool direct, string kind, string source)
        {
            DataRow row = _table.NewRow();
            row["ProjectId"] = _projectId;
            row["FromType"] = fromType;
            row["ToType"] = toType;
            row["Direct"] = direct;
            row["SubtypeKind"] = kind;
            row["Source"] = source;
            row["Omitted"] = false;
            _table.Rows.Add(row);
        }
    }

    internal class GenericInserter : DataInserter
    {
        private readonly int _projectId;
        private readonly DataTable _table;

        public GenericInserter(int projectId)
        {
            _projectId = projectId;
            _table = new DataTable();
            _table.Columns.Add("GenericId", typeof(long));
            _table.Columns.Add("ProjectId", typeof(int));
            _table.Columns.Add("FromType", typeof(int));
            _table.Columns.Add("ToType", typeof(int));
        }

        public async Task SaveAsync()
        {
            await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var adapter = GetAdapterForInsert(conn, "select * from Generic");
                    adapter.Update(_table);
                }
            });
        }

        public void AddItem(int fromType, int toType)
        {
            DataRow row = _table.NewRow();
            row["ProjectId"] = _projectId;
            row["FromType"] = fromType;
            row["ToType"] = toType;
            _table.Rows.Add(row);
        }
    }
}