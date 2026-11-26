import re


def strip(p):
    s = open(p, encoding='utf-8').read()
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    s = re.sub(r'//[^\n]*', '', s)
    return '\n'.join(l.strip() for l in s.split('\n') if l.strip())


a = strip('work/tmp_gpminput_pre_t35.c')
b = strip('project/app/src/main/assets/gpminput.c')
print('code_identical_to_t35_baseline=', a == b, len(a), len(b))
