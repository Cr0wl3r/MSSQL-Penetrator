use strict;
use warnings;
use DBI;
use Benchmark qw(:all);
use Threads;
#Anzahl der Durchläufe der Schleifen
my $Loops=10000;
#Benötigt einen DSN-Eintrag
my $DSN = "MSSQL";
#Aufbau der Verbindung zur Datenbank
my $dbh = DBI->connect("dbi:ODBC:$DSN")
	or die ("Can't connect to database \n");
	# Vorbereiten der Tabelle.
	print "Ueberpruefen ob Testtabelle existiert ...\n";
	#Existiert die Tabelle bereits wird sie gelöscht
	my $sql_tabledrop = "IF (OBJECT_ID('T1') is not null) DROP TABLE T1";
	#Anlegen der Testtabelle
	print "Anlegen der Testtabelle!";
	my $sql_tablecreate = "CREATE TABLE T1 (id int NOT NULL, daten nchar (20) NULL)";
	my $sth=$dbh->prepare($sql_tabledrop);
	$sth->execute();
	$sth->finish();
	$sth=$dbh->prepare($sql_tablecreate);
	$sth->execute() or die $sth->errstr;
	
		
	#----------------------------------------------------------------------
	#Benchmark der Schreibgeschwindigkeit auf die Tabelle
	#Benchmark Zeit starten
	print "Starte Insert Benchmark!";
	my $timeline1= new Benchmark;
	my $count1 = 0;
	
	while ($count1 < $Loops){
		#Befüllen der Tabelle mit Werten
		$sth=$dbh->prepare("INSERT T1(ID) values ($count1)");
		$sth->execute();
		$sth->finish();
		$count1 ++;
	}
	#Benchmark Zeit stoppen
	$timeline1= timediff (new Benchmark, $timeline1);
	print "Insert Benchmark beendet!\n";
	print "$count1 Inserts in:";
	my $bench_message = timestr($timeline1);
	print "$bench_message\n";
	#Loggen
	my $read_log_message = "WRITE: $bench_message";
	&bench_log($read_log_message);
	
	#Trennen der Verbindung zur Datenbank	
	$dbh->disconnect();
	print "Connection closed\n";
	
	#----------------------------------------------------------------------
	
	#Benchmark Read starten
	my $i=0;
	my $cores=8;
	print "CPU: $cores \n";
	print "Starte $cores Query Benchmarks mit jeweils $Loops Queries. \n";
	my @threads;
	while ($i < $cores){
		@threads[$i]=threads->new(\&bench_read);
		$i ++;
	}

	
	
	#---------------------------------------------------------------------
	#Benchmark der Lesegeschwindigkeit. 
	#Auslastung des Prozessors. Ein Thread kann nur einen Core belasten.
	# Benchmark Zeit starten
	sub bench_read {
		my $timeline2= new Benchmark;
		print "Starte Query Benchmark ...\n";
		#Aufbau der Verbindung zur Datenbank
			my $dbh = DBI->connect("dbi:ODBC:$DSN")
	or die ("Can't connect to database \n");
		my $count = 0;
		while ($count < $Loops){
			#Lesen jedes Wertes der Tabelle ohne Index
			my $sql_statement2 = "SELECT * FROM T1 WHERE ID=$count";
			$sth=$dbh->prepare($sql_statement2);
			$sth->execute() or die $sth->err_str;
			$sth->finish();
			$count ++;
		}
	
		#Benchmark Zeit stoppen
		$timeline2= timediff (new Benchmark, $timeline2);
		my $bench_message = timestr($timeline2);
		print "Query Benchmark beendet!\n";
		print "$count Queries in:";
		print "$bench_message\n";
		#Loggen
		my $write_log_message="READ: $bench_message";
		&bench_log($write_log_message);
		threads->exit();
		$dbh->disconnect();
	}
	
	#-----------------------------------------------------------------------
	

# Schreiben der Logdatei
# Übergabe Wert = Inhalt des Logs
sub bench_log {
	my $Logfile="sql_penetrator.log";
	if (-e $Logfile){ 
		open (LOG, ">> $Logfile") or die$!;
			print LOG $_[0] . "\n";
		close (LOG);
		}
		else {
			open (LOG, "> $Logfile") or die$!;
				print LOG $_[0] . "\n";
			close (LOG);
		}
}
$i=0;
while($i < $cores){
	@threads[$i]->join();
	$i ++;
}