#!/usr/bin/perl

use strict;
use warnings;
use Net::Twitter;
use Jcode;
use JSON::Syck;
use Data::Dumper;

#--[設定]--#
my $username = ""; # id
my $password = ""; # password
my $savefile = "/home/username/json.dat"; # 更新データの保存

#--[前処理]--#
my $twit = Net::Twitter->new(
    username=>$username,
    password=>$password
);

# --[処理]--#
my $newdata = JSON::Syck::Load(&get_newdata());
my $olddata = JSON::Syck::Load(&in_json());

#print JSON::Syck::Dump($newdata), "\n";
#print JSON::Syck::Dump($olddata), "\n";
#$newdata->{message} = "HOT: テスト";

if($newdata->{time} ne $olddata->{time}){
    # 自爆した場合はそこで終了
    if($newdata->{message} =~ /自爆しました/){
        exit(0);
    }

    # HOT: 付きの場合、HOT: を取り除く
    # そうでない場合は「が爆発しました。」を取り除く
    if($newdata->{message} =~ /^HOT:[\s\S]*/){
        $newdata->{message} =~ s/HOT:\s?//;
    }else{
        $newdata->{message} =~ s/が爆発しました。//;
    }
    # ". @"の整形
    $newdata->{message} =~ s/\.\s\@/\@/;
    # 空白の除去
    $newdata->{message} =~ s/　/ /g;
    $newdata->{message} =~ s/\s+$//g;
    # 整形
    $newdata->{message} = "\"". $newdata->{message} . "\"の悪口はそこまでよ!\n";
    # POSTする
    &post($newdata->{message});
    # 最新のデータを保存
    &out_json($newdata);
}

sub post{
    my $result = $twit->update(Jcode::convert($_[0], 'utf-8'));
    return $result;
}

sub get_newdata{
    my $twit = Net::Twitter->new(
        username=>$username,
        password=>$password
    );

    my $array_ref = $twit->friends();
    my $message = "";
    my $time = "";
    foreach my $hash_ref(@$array_ref){
        if($hash_ref->{'name'} eq "bombtter"){
            $message = Jcode::convert($hash_ref->{'status'}{'text'}, 'utf8');
            $time = $hash_ref->{'status'}{'created_at'};
        }
    }
    return "{\"message\" : \"$message\",\"time\" : \"$time\"}";
}

sub in_json{
    my $str_js = "";
    open(IN, $savefile) || die;
    while(<IN>){
        $str_js = $str_js . $_;
    }
    close(IN);
    return $str_js;
}

sub out_json{
    open(OUT, "> $savefile") || die;
    print OUT JSON::Syck::Dump($_[0]);
    close(OUT);
}
