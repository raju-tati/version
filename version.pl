use strict;
use warnings;
use utf8;
use Term::ANSIColor;
use Digest::MD5 qw(md5);
use JSON::PP;

sub readFile {
	my ($fileName) = @_;
	my $fileContent = "";

	open(my $fh, '<', $fileName) || die("Cannot open file");
	{
		local $/;
		$fileContent = <$fh>;
	}
	
	close($fh);
	return $fileContent;
}

sub writeFile {
	my ($fileName, $fileContent) = @_;
	
	open(my $fh, '>', $fileContent) || die("Cannot open file");
	print $fh $fileContent;
	close($fh);
}

sub splitStringOnWords {
	my ($string) = @_;
	my @stringList = split("", $string);

	my @splitStringOnWords;
	my $subString = "";

	foreach my $element (@stringList) {
		if($element eq "\n") {
			push(@splitStringOnWords, $subString);
			push(@splitStringOnWords, "\n");
			$subString = "";
		}

		elsif($element ne " ") {
			$subString .= $element;
		}
		
		else {
			push(@splitStringOnWords, $subString);
			push(@splitStringOnWords, " ");
			$subString = "";
		}
	}

	push(@splitStringOnWords, $subString);
	return @splitStringOnWords;
}

sub diff {
	my ($stringOne, $stringTwo) = @_;
	
	my @stringOneList = splitStringOnWords($stringOne);
	my @stringTwoList = splitStringOnWords($stringTwo);
	
	my $stringOneCounter = 0;
	my $stringTwoCounter = 0;
	
	my $diff = [];
	
	my $matchedPart = "";
	my $unMatchedPart = "";
	
	my $lastStringTwoMatchedPosition = 0;
	
	while(1) {
		if($stringOneList[$stringOneCounter] eq $stringTwoList[$stringTwoCounter]) {
			push(@{$diff}, ["unMatchedPart", $unMatchedPart]) if($unMatchedPart);
			$unMatchedPart = "";
			
			$matchedPart .= $stringOneList[$stringOneCounter];
	
			$stringOneCounter++;
			$stringTwoCounter++;
			$lastStringTwoMatchedPosition++;
		}
		
		else {
			push(@{$diff}, ["matchedPart", $matchedPart]) if($matchedPart);
			$matchedPart = "";
			$unMatchedPart .= $stringTwoList[$stringTwoCounter];
			$stringTwoCounter++;
		}
	
		if($stringOneCounter == scalar(@stringOneList)) { 	
			push(@{$diff}, ["matchedPart", $matchedPart]) if($matchedPart);
			push(@{$diff}, ["unMatchedPart", $unMatchedPart]) if($unMatchedPart);
			last;
		}
		
		if($stringTwoCounter == scalar(@stringTwoList) && $stringOneCounter < scalar(@stringOneList)) {
			$stringTwoCounter = $lastStringTwoMatchedPosition;
			push (@{$diff}, ["unMatchedPartInStringOne", $stringOneList[$stringOneCounter]]);
			$unMatchedPart = "";
			$stringOneCounter++;
			next;
		}
	
		if($stringTwoCounter == scalar(@stringTwoList)) {
			last;
		}
	}

	return $diff;
}

sub printDiff {
	my ($diff) = @_;

	foreach my $diffElement (@{$diff}) {
		if($diffElement->[0] eq "unMatchedPartInStringOne") {
			print color('bold red');
			print($diffElement->[1]); 			## UnMatched Part In Source File
		}
		
		if($diffElement->[0] eq "matchedPart") {
			print color('bold blue');
			print($diffElement->[1]);   		## Matched Part in Source File 
		}
		
		if($diffElement->[0] eq "unMatchedPart") {
			print color('bold yellow');
			print($diffElement->[1]);    		## UnMatched Part in Destination File 
		}
	}

	print color('reset');
}

sub printUsage {
	my $usageComment = 
"Usage:
		version initialize <filename>
		version display    <filename>
		version get        <filename>  <change_number>
		version combine    <filename>  <change_number>
		version diff 	   <filename>  <change_number> <change_number>
";

	print $usageComment;
}

sub versionDisplay {}

sub initialize {
	my ($fileName) = @_;
	my $versionFile = "." . $fileName;
	my $version = 0;
	
	my $newVersionFileName = $fileName . "_" . $version;
	
	my $versionDetails = [[0, [[[0,0], 0, "", ""]]]];	  	## [[versionNumber, [[[wordCountBegin, wordCountEnd], versionNumber, text, md5], ....]] ....]
	my $versionData = encode_json($versionDetails);
	
	writeFile($versionFile, $versionData);
	print($fileName, " initialized", "\n");
	
	writeFile($newVersionFileName, "Empty");
	print($newVersionFileName, " created");
}

## initialize
## printDiff
## versionDisplay
## get
## versionCombine

sub handleArgs {
	my (@args) = @_;
	my $fileName = $args[1];
	
	if($args[0] eq "initialize") { initialize($fileName); return; }
	if($args[0] eq "diff" && $args[2] && $args[3]) { printDiff(diff(get($fileName, $args[2]), get($fileName, $args[3]))); return; }
	if($args[0] eq "display") { versionDisplay($fileName); return; }
	if($args[0] eq "get" && $args[2]) { get($fileName, $args[2]); return; }
	if($args[0] eq "combine" && $args[2]) { versionCombine($fileName, $args[2]); return; }
	printUsage();
}

## program begin
my @args = @ARGV;
if(scalar(@args) > 4 || scalar(@args) < 2) { printUsage() } else { handleArgs(@args) };
