using NUnit.Framework;

namespace DatabaseTests
{
    [TestFixture]
    public class EmployeeLastPaycheckViewTests
    {
        private readonly DatabaseTestHelper _testerHelper;

        public EmployeeLastPaycheckViewTests()
        {
            _testerHelper = new DatabaseTestHelper();
        }

        [Test]
        public void ViewShouldReturnSomeData()
        {
            const string sql = @"
SELECT
        TOP 1
		*
	FROM
		vw_EmployeeLastPaycheck
";

            var dataSet = _testerHelper.GetDataSetForSql(sql);

            Assert.That(dataSet.Tables[0].Rows.Count, Is.EqualTo(1));
        }


        [Test]
        public void ViewShouldExist()
        {
            const string sql = @"
SELECT
		*
	FROM
		sysobjects WITH (NOLOCK)
	WHERE
		Name = 'vw_EmployeeLastPaycheck'";

            var dataSet = _testerHelper.GetDataSetForSql(sql);

            Assert.That(dataSet.Tables[0].Rows.Count, Is.EqualTo(1));
        }

        [Test]
        public void ViewShouldHaveUniqueEmplyeeIds()
        {
            const string sql = @"
SELECT
		EmployeeId
        , COUNT(1)
	FROM
		vw_EmployeeLastPaycheck
	GROUP BY
		EmployeeId
    HAVING
        COUNT(1) > 1";

            var dataSet = _testerHelper.GetDataSetForSql(sql);

            Assert.That(dataSet.Tables[0].Rows.Count, Is.EqualTo(0));
        }

        [Test]
        public void ViewShouldHaveUniqueCheckNumbers()
        {
            string sql = @"
SELECT
		PaycheckNumber
        , COUNT(1)
	FROM
		vw_EmployeeLastPaycheck
	GROUP BY
		PaycheckNumber
    HAVING
        COUNT(1) > 1";

            var dataSet = _testerHelper.GetDataSetForSql(sql);

            Assert.That(dataSet.Tables[0].Rows.Count, Is.EqualTo(0));
        }

    }
}