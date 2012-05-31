namespace DatabaseTests
{
    public class PaycheckTests : SingleTableTestsBase
    {
        protected override string TableName
        {
            get { return "Paycheck"; }
        }

        protected override string KeyColumns
        {
            get { return "PaycheckNumber"; }
        }
    }
}