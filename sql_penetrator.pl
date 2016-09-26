use strict;
use warnings;
use DBI;
use Benchmark qw(:all);
#Anzahl der Durchläufe der Schleifen
my $Loops=100000;
#Benötigt einen DSN-Eintrag
my $DSN = "MSSQL";
#Aufbau der Verbindung zur Datenbank
my $dbh = DBI->connect("dbi:ODBC:$DSN")
	or die ("Can't connect to database \n");
print "Connection established\n";

	print "Ueberpruefen ob Testtabelle existiert ...\n";
	my $sql_tabledrop = "IF (OBJECT_ID('T1') is not null) DROP TABLE T1";
	my $sql_tablecreate = "CREATE TABLE T1 (id int NOT NULL, daten nchar (20) NULL)";
	my $sth=$dbh->prepare($sql_tabledrop);
	$sth->execute();
	$sth->finish();
	$sth=$dbh->prepare($sql_tablecreate);
	$sth->execute() or die $sth->errstr;
	
		
	#----------------------------------------------------------------------
	#Benchmark Zeit starten
	my $timeline1= new Benchmark;
	my $count1 = 0;
	
	while ($count1 < $Loops){
		$sth=$dbh->prepare("INSERT T1(ID) values ($count1)");
		$sth->execute();
		$sth->finish();
		$count1 ++;
	}
	#Benchmark Zeit stoppen
	$timeline1= timediff (new Benchmark, $timeline1);
	print "Insert Benchmark beendet!\n";
	
	
	#---------------------------------------------------------------------
	# Benchmark Zeit starten
	my $timeline2= new Benchmark;
	print "Starte Query Benchmark ...\n";
	my $count = 0;
	while ($count < $Loops){
		my $sql_statement2 = "SELECT * FROM T1 WHERE ID=$count";
		$sth=$dbh->prepare($sql_statement2);
		$sth->execute() or die $sth->err_str;
		$sth->finish();
		$count ++;
	}
	
	#Benchmark Zeit stoppen
	$timeline2= timediff (new Benchmark, $timeline2);
	print "Query Benchmark beendet!\n";
	
	#-----------------------------------------------------------------------
	# Ausgabe Ergebnis
	print "$count1 Inserts in:";
	print timestr($timeline1) . "\n";
	print "$count Queries in:";
	print timestr($timeline2) . "\n";

#Trennen der Verbindung zur Datenbank	
$dbh->disconnect();
print "Connection closed\n";

# Schreiben der Logdatei
my $Logfile="sql_penetrator.log";
if (-e $Logfile){ 
	open (LOG, ">> $Logfile") or die$!;
		print LOG timestr($timeline1) . "\n";
		print LOG timestr($timeline2) . "\n";
	close (LOG);
	}
	else {
		open (LOG, "> $Logfile") or die$!;
			print LOG timestr($timeline1) . "\n";
			print LOG timestr($timeline2) . "\n";
		close (LOG);
	}
