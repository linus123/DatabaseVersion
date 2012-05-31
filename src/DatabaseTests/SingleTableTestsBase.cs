using System;
using NUnit.Framework;

namespace DatabaseTests
{
    public abstract class SingleTableTestsBase
    {
        protected DatabaseTestHelper DatabaseTestHelper;

        protected SingleTableTestsBase()
        {
            DatabaseTestHelper = new DatabaseTestHelper();
        }

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

            var dataSet = DatabaseTestHelper.GetDataSetForSql(sql);

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

            var dataSet = DatabaseTestHelper.GetDataSetForSql(sql);

            Assert.That(dataSet.Tables[0].Rows.Count, Is.EqualTo(0));
        }

    }
}