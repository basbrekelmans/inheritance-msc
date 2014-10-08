using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InheritanceInsertion.ViewModel
{
    class RelationInserter : DataInserter
    {
        private readonly int _projectId;
        private readonly DataTable _table;

        private readonly Dictionary<long, DataRow> _existingRelations = new Dictionary<long, DataRow>();

        public RelationInserter(int projectId)
        {
            _projectId = projectId;
            _table = new DataTable();
            _table.Columns.Add("ProjectId", typeof (int));
            _table.Columns.Add("FromType", typeof(int));
            _table.Columns.Add("ToType", typeof(int));
            _table.Columns.Add("RelationType", typeof(string));
            _table.Columns.Add("DirectRelation", typeof(bool));
            _table.Columns.Add("Marker", typeof(bool));
            _table.Columns.Add("Constants", typeof(bool));
            _table.Columns.Add("SystemType", typeof(bool));

        }

        public async Task SaveAsync()
        {
            await Task.Run(async () =>
            {
                using (var conn = await CreateConnectionAsync())
                {
                    var adapter = GetAdapterForInsert(conn, "select * from TypeRelation");
                    adapter.Update(_table);
                }
            });
        }

        public void AddItem(string relationType, int fromType, int toType, bool directRelation, bool marker,
            bool constants, bool systemType)
        {
            long key = ((long) fromType << 32) + toType;
            DataRow row;
            if (!_existingRelations.TryGetValue(key, out row))
            {
                row = _table.NewRow();
                row["ProjectId"] = _projectId;
                row["FromType"] = fromType;
                row["ToType"] = toType;
                row["RelationType"] = relationType == "IC" ? "II" : relationType;
                row["DirectRelation"] = directRelation;
                row["Marker"] = marker;
                row["Constants"] = constants;
                row["SystemType"] = systemType;
                _existingRelations.Add(key, row);
                _table.Rows.Add(row);
            }
            else
            {
                row["SystemType"] = (bool)row["SystemType"] || systemType;
            }
        }
    }
}
