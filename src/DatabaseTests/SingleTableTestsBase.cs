using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using NUnit.Framework;

namespace DatabaseTests
{
    public abstract class SingleTableTestsBase
    {
        protected abstract string TableName { get; }
        protected abstract string KeyColumns { get; }

        [Test]
        public void TableShouldExist()
        {
            const string sqlTemplate = @"
SELECT
        TOP 1
        *
    FROM
        {0}
";

            var sql = string.Format(sqlTemplate, TableName);

            var dataSet = GetDataSetForSql(sql);

            Assert.Pass();
        }

        [Test]
        public void TableShouldHaveUniqueKey()
        {
            const string sqlTemplate = @"
SELECT
        TOP 1
        {0},
        COUNT(1)
    FROM 
        {1}
    GROUP BY 
        {0}
    HAVING COUNT(1) > 1
";
            var sql = String.Format(sqlTemplate, KeyColumns, TableName);

            var dataSet = GetDataSetForSql(sql);

            Assert.That(dataSet.Tables[0].Rows.Count, Is.EqualTo(0));
        }

        protected void ExecuteWithConnection(Action<SqlConnection> connectionAction)
        {
            var connectionString = ConfigurationManager.ConnectionStrings["LocalDatabase"].ConnectionString;

            using (var sqlConnection = new SqlConnection(connectionString))
            {
                sqlConnection.Open();
                connectionAction(sqlConnection);
                sqlConnection.Close();
            }

        }

        protected DataSet GetDataSetForSql(string sql)
        {
            var dataSet = new DataSet();

            ExecuteWithConnection(
                sqlConnection =>
                {
                    var sqlCommand = new SqlCommand(sql, sqlConnection);
                    sqlCommand.CommandType = CommandType.Text;
                    var sqlDataAdapter = new SqlDataAdapter(sqlCommand);

                    sqlDataAdapter.Fill(dataSet);
                });
            return dataSet;
        }
    }
}