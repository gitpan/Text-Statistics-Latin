package Text::Statistics::Latin;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

# $Id: Latin.pm,v 1.0 2007/06/12 09:17:36 rpfernandes Exp $
#Copyright (c) 2007 Rodrigo Panchiniak Fernandes. All rights reserved.
#
# 
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
=head1 NAME

Text::Statistics::Latin - performs corpora statistical analyses

=head1 SYNOPSIS

  use CText::Statistics::Latin; 
  &Text::Statistics::Latin:LATIN();

=head1 DESCRIPTION

Text::Statistics::Latin creates a seven column CSV file output with one line each
token per text given as input a corpus that files names follows '
    1 (1). txt', '1 (2). txt', ..., '1 (n).txt'  or
    1 \(([1-9]|[1-9][0-9]+)\)\.txt
Columns stores statistical information:
(1) number of word forms in document d;
(2) number of tokens in d;
(3) Id number of d, ie., n;
(4) frequency of term t in d;
(5) corpus frequency of t ;
(6) document frequency of t (number of documents where t occurs at least once);
(7) t, UTF8 latin coded token-string

Main output file name is '1 (n + 5).txt' and it is stored in the same directory as
the corpus itself, toghether with residual files on each input file with .txu and .txv extensions.

This code was written under CAPES BEX-09323-5

=head2 Methods

Example:

#!/usr/bin/perl 
use strict;
use Text::Statistics::Latin;

&Text::Statistics::Latin::LATIN("5");     #4 files (5 - 1) are analysed.

=over
=cut
use 5.006;
our $VERSION = '0.02';
use Text::ParseWords;
use utf8;

use vars qw($VERSION @ISA);

sub LATIN{
    
    print "inicio de programa, aguardes", "\n";
    my $min = 1;                                                                    #número do arquivo inicial
    our $max=shift;
    
    my $dif = $max - $min;
    my $tempo = 1;
    
    while ($tempo < 3){                                                             #limita o procedimenento aos ciclos inicial e meta-dado
        my $nome4 = "1 ($max).txt";                                                 #arquivo de mescla para a obtenção automática de df                                        
        my $nome5 = "registro1 ($max).txt";	                                        #arquivos de log dos dados e dos metadados
        open (our $result, ">", $nome4) || die "Não posso escrever $nome4: $!";                
        open (my $registro, ">", $nome5) || die "Não posso escrever $nome5: $!";
        my $num = $min;                                                             #número do arquivo inicial
        my $maximo = $max;                                                          #número do arquivo final + 1
        while ($num < $maximo){        
            
            my $nome1 = "1 ($num).txt";                                             #arquivos de texto
            my $nome2 = "1 ($num).txu";                                             #\sToken\n
            my $nome3 = "1 ($num).txv";                                             #Número do arquivo,Frequencia,\sType
            
            my $i = 1;                                                              #primeira string
            my $reg = /\r\n/;                                                       #necessário para a limpeza em UTF-8
            my $reg2 = /\s/;                                                        #devido a um erro conhecido (cf. www.unicode.org,
            #http://unicode.org/reports/tr13/tr13-5.html)
            
            ###início módulo de tokenização
            
            open (my $in, "<", $nome1) || die "Can not open", $nome1, ": $!";
            open (my $out, ">", $nome2) || die "Can not write", $nome2, ": $!";
            print "inicio de tokenização, aguardes", "\n"; 
            
            while (1) {
                my $line = <$in>;
                our $tokens = $i;            
                last unless $line;
                for ($line) {                
                    s/[-@]|[\[-`]|[{-¿]|[ɐ-˩]|[ʹ-�]/ /g;                               #separadores para idiomas exclusivamente de alfabto latino  
                }   
                @words = &shellwords(' ', 0, $line);                                    #separador anterior: \s+
                foreach (@words) {
                    unless ($_ eq "s+"|$_ eq "0"|$_ eq $reg|$_ eq $reg2){      #limpeza final                    
                        print $out " $_\n";
                        $i++;
                    }
                }     
            }
            close $in;
    
            if ($tempo < 2){
                our $tokensgeral = $tokensgeral + $tokens;
            }
            close $out;
            print "fim de tokenização", "\n";
            print "início de typeficação, aguardes", "\n";
            
            # início módulo de contagem de frequência ("typeficação")
            
            my $ii = ($i - 1);                                                      #úlitma string processada no módulo anterior - 1
            open (my $in2, "<", $nome2) || die "Can not open $nome2: $!";
            open (my $out2, ">", $nome3) || die "Can not write $nome3: $!";
            our @lista = <$in2>;
            my $controle2 = 0;
            my $types = 0;
            while ($controle2 < $ii){
                our $inicio = -1;
                my $controle = 0;                                                   #freqüência dos termos
                my $pesquisa = $lista[$controle2];                                  #termos pesquisado
                while (1){
                    last unless ($lista[$inicio]);
                    foreach ($lista[$inicio]){        
                        $inicio++;
                        if ($lista[$inicio] =~ /$pesquisa/i){                       #localiza a palavra 
                            $controle++;                                            #acrescenta um "feijão"
                        }   
                    }
                }
                if ($controle < $ii){
                    $types++;
                    print $out2 "$num,$controle,$pesquisa";
                    print $result $num, ",", $controle, ",", $pesquisa;             #não deu                
                }
                for (@lista){
                    s/$pesquisa/\n/i;                                               #limpa o que já foi calculado, para minimizar os esforços.                                       
                }
                $controle2++; 
            }
            print "Foram encontrados ", $types, " types no arquivo ", $nome1, "!", "\n";
            print $registro $types, ",", $ii, ",", $nome1, "\n";        
            close $in2;
            close $out2;
            $num++;
        } 
        close $result;
        $tempo++;                                                                   #acrescenta um "feijão" ao tempo
        $min = $max;                                                                #alteram o intervalo de alvos
        $max++;                                                                     #para a extração dos meta-dados
        print "fim de typeficação", "\n";
        print "início de primeira contagem, aguardes", "\n";
        
        # início do módulo de frequencia da coleção
        
        if ($tempo == 3){       
            do{
            $num = $num - 1;
            my $nome1 = "1 ($num).txv";
            my $nome2 = "1 ($num).txt";
            
            $num = $num + 2;
            my $nome3 = "1 ($num).txt";
            
            open (my $in1, "<", $nome1) || die "Não posso abrir $nome1: $!";                
            open (my $in2, "<", $nome2) || die "Não posso abrir $nome2: $!";
            open (my $out1, ">", $nome3) || die "Não posso escrever $nome3: $!";
            
            my @in1 = <$in1>;
            my @in2 = <$in2>;
            
            my $tempo1 = 0;
            
            while ($in1[$tempo1]){  
                my $linha1 = $in1[$tempo1];
                for ($linha1){
                    s/.+,.+, / /g;
                }    
                my $tempo2 = 0;
                my $cont = 0;
                while ($in2[$tempo2]){
                    my $linha2 = $in2[$tempo2];
                    if ($linha2 =~ /.+,.+,$linha1/i){            
                        for ($linha2){
                            s/[^0-9]/ /ig;
                            s/[0-9]+\s//;
                        }            
                        for ($linha2){
                            $cont = $cont + $linha2;                
                        }                    
                    }      
                    $tempo2++;
                }    
                $out11[$tempo1] = "$cont,$linha1";                                  #ok
                $tempo1++;   
            }
            close $in1;
            close $in2;
            print $out1 @out11;
            close $out1;
            print "fim de primeira contagem", "\n";        };
            
            #inicio modulo de unificação tf df cf
            #onde se cria o arquivo cf,df, termo, penúltimo na lista txt.
         
            do{
                print "início de terceira contagem, aguardes", "\n";
                my $numm = $num - 2;
                my $nome2 = "1 ($num).txt";
                open (my $incf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num - 1;
                $nome2 = "1 ($num).txt";
                open (my $indf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num + 2;
                $nome2 = "1 ($num).txt";
                open (my $out, ">", $nome2) || die "Não posso abrir $nome2: $!";
                
                my @lista1 = <$indf>;
                my @lista2 = <$incf>;
                my $linha = 0;
                
                while(1){
                    last unless ($lista1[$linha]);                              
                    for ($lista1[$linha]){
                        s/$numm,//i;
                    }
                    for ($lista2[$linha]){
                        s/, .+//;
                        s/\n//;
                    }   
                    print $out "$lista2[$linha],$lista1[$linha]";
                    $linha = $linha + 1;
                }
                close $out;
                close $incf;
                close $indf;
                print "fim de terceira contagem", "\n";
                
                #inicio módulo de união final - doc, tf, cf, df, termo, cria o último txt
                
                print "inicio de unificação, aguardes", "\n";
                open (my $incfdf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num - 3;
                $nome2 = "1 ($num).txt";
                open (my $intf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num + 4;
                $nome2 = "1 ($num).txt";
                open (my $outtot, ">", $nome2) || die "Não posso abrir $nome2: $!"; #arquivo de união final
                                                                                                                    #texto, tf, cf, df, termo
                my @listatf = <$intf>;
                my @listadf = <$incfdf>;
                my @listadf1 = @listadf;
                my $linhatf = 0;

                while (1){
                    last unless ($listatf[$linhatf]);
                    my $linhadf = 0;
                    while (1){
                        last unless ($listadf[$linhadf]);
                        for ($listadf[$linhadf]){
                            s/.+,.+,//;
                        }                
                        if ($listatf[$linhatf] =~ /.+,.+,$listadf[$linhadf]/i){     #localiza a linha em df na qual ocorre
                                                                                                #o termo de cada linha de tf
                            for ($listatf[$linhatf]){
                                s/, .+\n/,/i;
                            }                        
                            $outtott[$listadf[$linhatf]] = "$listatf[$linhatf]$listadf1[$linhadf]";
                        }            
                        $linhadf++;
                    }
                    print $outtot @outtott;
                    $linhatf++;                    
                }
                print "fim de unificação", "\n";
                close $outtot;
                close $intf;
                close $incfdf;
                print "inicio de unificação para Okapi BM 25", "\n";

                #início módulo de unificação de frequencia total de ocorrências por documento (para Okapi BM 25)

                my $znum = $num;
                open (my $zincinco, "<", "1 ($znum).txt") || die "Não posso escrever registro1 ($znum).txt: $!";
                my @zin2 = <$zincinco>;
                my @zin3 = @zin2;
                $znum++;
                open (my $zoutx, ">", "1 ($znum).txt") || die "Não posso escrever 1 ($znum).txt: $!";
                $znum = $znum - 5;        
                open (my $zregistro, "<", "registro1 ($znum).txt") || die "Não posso escrever registro1 ($znum).txt: $!";          
                my @zin1 = <$zregistro>;
                my $zindex = 0;
                my $zinic = 0;
                while (1){
                    last unless ($zin1[$zinic]);
                    my $zlinhac = 0;            
                    for ($zin1[$zinic]){
                        s/1 .+\n//;
                    }            
                    my $zinicc = $zinic + 1;            
                    while (1){
                        last unless ($zin2[$zlinhac]);
                        for ($zin3[$zlinhac]){
                            s/,.+\n//;
                        }                
                        if ("$zin3[$zlinhac]\n" =~ /$zinicc\n/){
                            print $zoutx "$zin1[$zinic]$zin2[$zlinhac]";
                            $zindex++;
                        }                    
                        $zlinhac++;
                    }
                    $zinic++;            
                }
            };       
            $tokensgeral = $tokensgeral - $dif;
            print "Neste corpus há ", $tokensgeral, " tokens!", "\n";               #exportar esta informação para o último registro
        }  
    }
    print "\n", "fim de programa";
}

1;