ALTER DATABASE DataTrue_Main SET single_user with rollback immediate;
ALTER DATABASE DataTrue_EDI SET single_user with rollback immediate;

DROP DATABASE DataTrue_Main;
DROP DATABASE DataTrue_EDI;