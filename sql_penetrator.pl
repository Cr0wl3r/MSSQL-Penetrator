use strict;
use warnings;
use DBI;
use Benchmark qw(:all);
use Threads;
use Threads::shared;
#Anzahl der Durchläufe der Schleifen
my $Loops=100000;
#Benötigt einen DSN-Eintrag
my $DSN = "MSSQL";
#Angabe der CPU Cores
my $cores=8;
#Initialisierung des Logfiles
&bench_log();
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
	my $read_log_message = $bench_message;
	# ersetze Alles nach dem ersten Leerzeichen durch Leerstring
	substr($read_log_message, index($bench_message, ' ', 1)) = '';
	&bench_log($read_log_message . ";");
	&bench_log($Loops . ";");
	
	#Trennen der Verbindung zur Datenbank	
	$dbh->disconnect();
	print "Connection closed\n";
	
	#----------------------------------------------------------------------
	
	#Benchmark Read starten
	my $i=0;
	#Benchmark Zeit aller Queries
	my $timeline3=new Benchmark;
	print "CPU: $cores \n";
	print "Starte $cores Query Benchmarks mit jeweils $Loops Queries. \n";
	my @threads;
	my $thread_ends :shared;
	$thread_ends=0;
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
		my $write_log_message="$bench_message";
		# ersetze Alles nach dem ersten Leerzeichen durch Leerstring
		substr($write_log_message, index($bench_message, ' ', 1)) = '';
		&bench_log($write_log_message . ";");
		threads->exit();
		$dbh->disconnect();
		$thread_ends++;
	}
	
	#-----------------------------------------------------------------------
	

# Schreiben der Logdatei
# Übergabe Wert = Inhalt des Logs
sub bench_log {
	my $Logfile="sql_penetrator.log";
	if (-e $Logfile){ 
		#Eintrag generieren in CSV File
		open (LOG, ">> $Logfile") or die$!;
			print LOG $_[0];
		close (LOG);
		}
		#Initialisiere Logfile
		#CSV Header werden geschrieben
		else {
			open (LOG, "> $Logfile") or die$!;
				print LOG "Write;";
				print LOG "Queries;";
				$i=0;
				while($i< $cores){
					print  LOG "READ;";
					$i++;
				}
				print LOG "ALL READ;";
				#wird nicht mehr gebraucht wenn am Anfang das Logfile initialisiert wird.
				#print LOG $_[0] . "\n";
				print LOG "\n";
			close (LOG);
		}
}
$i=0;
while($i < $cores){
	@threads[$i]->join();
	$i ++;
}
	$timeline3= timediff (new Benchmark, $timeline3);
	print "Alle Query Benchmarks beendet!\n";
	print "$count1*$cores Inserts in:";
	my $bench_message = timestr($timeline3);
	print "$bench_message\n";
	#Loggen
	my $all_log_message = $bench_message;
	# ersetze Alles nach dem ersten Leerzeichen durch Leerstring
	substr($all_log_message, index($bench_message, ' ', 1)) = '';
	&bench_log($all_log_message . ";");
&bench_log("\n");