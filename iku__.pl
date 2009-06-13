#!/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;
use Jcode;
use Time::Local;
use Encode;
use Net::Twitter;

#--[設定]--#
my $log = "/home/username/timestamp.log"; # 更新ログ
my $url = "http://severe.worldweather.wmo.int/thunder/b3/history0.html"; # 最新の雷情報
my $username = ""; # id
my $password = ""; # password

#--[処理]--#
my $xml = Jcode::convert(LWP::UserAgent->new->get($url)->content, "utf-8", "euc");

# timestamp ログの確認
open(IN, $log) || die "Error: $!\n";
my @log = <IN>;
close(IN);

my $tt = shift(@log);
chomp($tt);

# 最新のtimestampを取得
my $ltt = &getJSTTime($xml);

unshift(@log, $tt, "\n");
unshift(@log, $ltt."\n");
open(OUT, "> $log") || die "Error: $!\n";
print OUT @log;
close(OUT);

# ログと最新の timestamp を比較
if($tt ne $ltt){
	#print $tt, "\n";
	#print $ltt, "\n";
	&execute($xml, $ltt);
}
exit(0);

sub execute{
	my @message;
	foreach (&xmlsplit($_[0])){
		if(/JAPAN/){
			my $point = $1 if(/<div class=\"coordinate\">\((.*?)\)<br>/);
			my ($n1, $n2, $w1, $w2) = $point =~ /(\w+) (\w+)N (\w+) (\w+)E/;
			my $url = "http://refits.cgk.affrc.go.jp/tsrv/jp/rgeocode.php?v=1&lat=$n1.$n2&lon=$w1.$w2";
			my $xml = LWP::UserAgent->new->get($url)->content;
			my $data = XMLin($xml);
			#print Dumper($data);
			my $city = encode('utf-8', $data->{prefecture}->{pname});
			my $town = encode('utf-8', $data->{municipality}->{mname});
			push(@message, "$_[1]、$city $town");
		}
	}
	if($#message >= 0){
		my $twit = Net::Twitter->new(
  			username=>$username,
			password=>$password
		);
		my $message = pop(@message). "付近で、雷が発生した模様です。";
		#print $message,"\n";
		$twit->update(Jcode::convert($message, 'utf-8'));
		foreach(@message){
			my $message = $_;
			$message = "続いて、$message付近でも、雷が発生した模様です。";
			sleep(60);
			#print $message, "\n";
			$twit->update(Jcode::convert($message, 'utf-8'));
		}
	}
}

sub xmlsplit{
	my @list;
	push(@list, $_[0] =~ /<tr>[\s\S]*?<\/tr>/g);
	return @list;
}

sub getJSTTime{
	my %convert = (
		"January"=>1,
		"February"=>2,
		"March"=>3,
		"April"=>4,
		"May"=>5,
		"June"=>6,
		"July"=>7,
		"August"=>8,
		"September"=>9,
		"October"=>10,
		"November"=>11,
		"December"=>12
	);
	
	my @latest = $_[0] =~ /<div class=\"header\">\&nbsp\; Thunderstorms Report\(s\) as at (\w+) UTC (\w+) (\w+) (\w+)<\/div>/;
	#my @latest = $_[0] =~ /<div class=\"header\">\&nbsp\; Heavy Rain\/Snow Report\(s\) as at (\w+) UTC (\w+) (\w+) (\w+)<\/div>/;

	my $jst = timelocal(0,0,$latest[0],$latest[1],$convert{$latest[2]},$latest[3]-1900) + 60 * 60 * 9; 
	my($sec, $min, $hour, $day, $mon, $year) = localtime($jst);
	#return sprintf("%02d/%02d/%02d %02d:%02d:%02d", $year+1900,$mon,$day,$hour,$min,$sec)."\n";
	my $hour_m = sprintf("午前%02d時頃", $hour);
	if($hour > 12){
		$hour = $hour - 12;
		$hour_m = sprintf("午後%02d時頃", $hour);
	}
	return sprintf("%d日%s", $day,$hour_m);
}
