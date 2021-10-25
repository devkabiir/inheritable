# see https://github.com/flutter/flutter/issues/27997#issue-410722816
find lib '!' -path '*generated*/*' '!' -name '*.g.dart' '!' -name '*.part.dart' '!' -name '*.freezed.dart' -name '*.dart' | cut -c4- | awk -v package=$1 '{printf "import '\''package:capp_bauhaus%s%s'\'';\n", package, $1}' >> test/coverage_helper_file.dart

echo "void main(){}" >> test/coverage_helper_file.dart