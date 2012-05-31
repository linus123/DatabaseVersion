using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace DatabaseTests
{
    public class DatabaseTestHelper
    {
        public void ExecuteWithConnection(Action<SqlConnection> connectionAction)
        {
            var connectionString = ConfigurationManager.ConnectionStrings["LocalDatabase"].ConnectionString;

            using (var sqlConnection = new SqlConnection(connectionString))
            {
                sqlConnection.Open();
                connectionAction(sqlConnection);
                sqlConnection.Close();
            }

        }

        public DataSet GetDataSetForSql(string sql)
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