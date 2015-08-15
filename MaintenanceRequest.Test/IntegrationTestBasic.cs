using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MaintenanceRequestLibrary;
namespace MaintenanceRequestLibrary.Test
{



    [TestClass]
  public class IntegrationTestBasic
  {

        [TestInitialize]
        public void initialize()
        {
            Logger.Log("****STARTING TEST*****");
        }



        [TestMethod]
        [Description("Tests basic insert of cost record")]
    public void TestBasicCostRecordSaves()
    {
            
       
            //Generate a standard Cost record
            var costRecord = new CostModel("ABCTEST");
            string statement = EDIMockFactory.createCostRecord(costRecord);

            //Execute the statement against the DataTrue_EDI database, and get the number of rows affected
            int affectedRows = new DatabaseAction().execute(statement, MRDatabase.EDI);

            //Make sure that one row was inserted
            Assert.AreEqual(affectedRows, 1);
    }

    [TestMethod]
    public void TestThatCostRecordForNewItemCreatesANewItem()
    {

        
        
        //Generate a standard Cost record
        var newCostRecord = new CostModel("NEWITEMTEST");
        newCostRecord.requestTypeId = 1;
        string statement = EDIMockFactory.createCostRecord(newCostRecord);

        //Insert new cost record
        new DatabaseAction().execute(statement, MRDatabase.EDI);

        //Get count of records before job runs
        var validator = new Validator();
        int preCount = validator.EDItoMRTableCount(newCostRecord.upc);

        //Run the job which should move the cost record to DataTrue_MAIN.maintenancerequests table
        new MRJobManager().runMRJobs();    

        //now validate that we have one more record than we did before
        //Assert.AreEqual(validator.EDItoMRTableCount(newCostRecord.upc), preCount + 1);
    }

    [TestMethod]
    public void TestThatCostUpdateUpdatesProductCost()
    {
        //Generate a standard Cost record
        var costUpdateRecord = new CostModel("UPDATETEST");
        costUpdateRecord.requestTypeId = 2;
        costUpdateRecord.cost = 11.59m;
        
        string statement = EDIMockFactory.createCostRecord(costUpdateRecord);

        //Insert new cost record
        new DatabaseAction().execute(statement, MRDatabase.EDI);

        //Run the job which should move the cost record to DataTrue_MAIN.maintenancerequests table
        new MRJobManager().runMRJobs(); 

        //TODO: Query the product in DataTrue_MAIN and assert cost is updated.
    }

  }
}
