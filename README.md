== Description
MSSQL-Penetrator benchmarks a Microsoft SQL Server in read and write speed.
Software is tested with MSSQL Server 2008R2

== Requirements
   - Microsoft SQL Server 2008R2 (other versions not tested yet)
   - Installation of Perl
   - Database which will be used for benchmarking
   - Configured DSN which will be used to connect to the database
   
== Usage
  Usage: sql_penetrator.pl [cores] [loops] [dsn]
  
	Options: [cores]    Number of course on the system the benchmark will run. Use carefully. Per core the applications will create one query benchmark.
	         [loops]    Number of entries in the database. Try how much yoursystem can handle.
	         [dsn]      Name of the DSN entry which will be used to connect to the MSSQL database.
           
	Example:  sql_penetrator.pl 8 1000000 MSSQL

