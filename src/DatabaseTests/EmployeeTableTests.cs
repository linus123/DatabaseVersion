using NUnit.Framework;

namespace DatabaseTests
{
    [TestFixture]
    public class EmployeeTableTests : SingleTableTestsBase
    {
        protected override string TableName
        {
            get { return "Employee"; }
        }

        protected override string KeyColumns
        {
            get { return "EmployeeId"; }
        }
    }
}