#!/usr/bin/perl
use strict; use warnings;
use FileHandle;

my($file_gff)=@ARGV;

my $in=FileHandle->new("< $file_gff");

my(%hash_gene, %hash_mRNA, %hash_CDS, %hash_exon, %hash_strand);
my $header=<$in>;
while(<$in>){
	chomp;
	my @arr=split("\t", $_);
	if($arr[2]=~/gene/){
		$arr[8]=~/ID=([^;]+);/;
		my $geneID=$1;
		$hash_gene{$geneID}=$_;
		$hash_strand{$geneID}=$arr[6];
	}else{
		$arr[8]=~/Parent=([^;]+)/;
		my $geneID=$1;
		if($arr[2]=~/mRNA/){
			$hash_mRNA{$geneID}=$_;
		}elsif($arr[2]=~/CDS/){
			if(!exists($hash_CDS{$geneID})){
				my @arr_CDS=($_);
				$hash_CDS{$geneID}=\@arr_CDS;
			}else{
				push @{$hash_CDS{$geneID}}, $_;
			}
		}elsif($arr[2]=~/exon/){
			if(!exists($hash_exon{$geneID})){
				my @arr_exon=($_);
				$hash_exon{$geneID}=\@arr_exon;
			}else{
				push @{$hash_exon{$geneID}}, $_;
			}
		}
	}
}

foreach my $key (keys %hash_gene){
	if(exists$hash_exon{$key}){
		print "$hash_gene{$key}\n";
		print "$hash_mRNA{$key}\n";
		for(my $i=0; $i<@{$hash_CDS{$key}}; $i++){
			print "${$hash_exon{$key}}[$i]\n";
			print "${$hash_CDS{$key}}[$i]\n";
		}
	}else{
		print "$hash_gene{$key}\n";
		print "$hash_mRNA{$key}\n";
		if($hash_strand{$key}=~/\+/){
			for(my $i=0; $i<@{$hash_CDS{$key}}; $i++){
				my $number=$i+1;
				my $cds=${$hash_CDS{$key}}[$i];
				${$hash_CDS{$key}}[$i]=~s/CDS/exon/;
				${$hash_CDS{$key}}[$i]=~s/ID=cds.([^;]+);/ID=$1.exon$number/;
				print "${$hash_CDS{$key}}[$i]\n";
				print "$cds\n";
			}
		}elsif($hash_strand{$key}=~/-/){
			for(my $i=0; $i<@{$hash_CDS{$key}}; $i++){
				my $number=@{$hash_CDS{$key}}-$i;
				my $cds=${$hash_CDS{$key}}[$i];
				${$hash_CDS{$key}}[$i]=~s/CDS/exon/;
				${$hash_CDS{$key}}[$i]=~s/ID=cds.([^;]+);/ID=$1.exon$number;/;
				print "${$hash_CDS{$key}}[$i]\n";
				print "$cds\n";
			}
		}
	}
}
