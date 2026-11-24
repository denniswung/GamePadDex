import subprocess

old = open('work/tmp_gpminput_pre_t35.c', encoding='utf-8').read().split('\n')
new = open('project/app/src/main/assets/gpminput.c', encoding='utf-8').read().split('\n')


def code_prefix(line):
    i = line.find('/*')
    if i > 0 and line[:i].strip():
        return line[:i].rstrip()
    return None


d = subprocess.run(['diff', '-u', 'work/tmp_gpminput_pre_t35.c',
                    'project/app/src/main/assets/gpminput.c'],
                   capture_output=True, text=True).stdout.split('\n')
removed = [l[1:] for l in d if l.startswith('-') and not l.startswith('---')]
added = [l[1:] for l in d if l.startswith('+') and not l.startswith('+++')]

code_removed = [l for l in removed if code_prefix(l) is not None]
code_added = [l for l in added if code_prefix(l) is not None]
print('code_lines_removed=', len(code_removed))
print('code_lines_added=', len(code_added))
print('hash_stable_prefixes=', sorted(code_prefix(l) for l in code_removed) == sorted(code_prefix(l) for l in code_added))
bad = [(a, b) for a, b in zip(sorted(code_removed), sorted(code_added))
       if code_prefix(a) != code_prefix(b)]
print('prefix_mismatch=', len(bad))
for a, b in bad[:5]:
    print('OLD', a)
    print('NEW', b)
