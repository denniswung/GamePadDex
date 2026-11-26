p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()
bad = 'int main(int argc, char **argv) {int main(int argc, char **argv) {'
print('found:', bad in s)
s = s.replace(bad, 'int main(int argc, char **argv) {', 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('fixed')
