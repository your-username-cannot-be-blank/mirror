import subprocess
import re
import sys
import os

# Функция для загрузки IP-адресов из файла
def load_ip_list(filename):
    if os.path.exists(filename):
        with open(filename, 'r') as f:
            return set(line.strip() for line in f if line.strip())
    return set()

# Функция для добавления IP-адреса в ipset и файл
def add_ip(ip, ip_set, filename):
    if ip not in ip_set:
        try:
            subprocess.run(['ipset', 'add', 'redirect_domains', ip], check=True)
            print(f"Добавлен IP: {ip}")
            ip_set.add(ip)
            with open(filename, 'a') as f:
                f.write(f"{ip}\n")
        except subprocess.CalledProcessError:
            print(f"Не удалось добавить IP: {ip}", file=sys.stderr)

# Загрузка списка IP-адресов
ip_list = load_ip_list('ip_list.txt')

# Добавление существующих IP-адресов в ipset
for ip in ip_list:
    try:
        subprocess.run(['ipset', 'add', 'redirect_domains', ip], check=True)
        print(f"Добавлен существующий IP: {ip}")
    except subprocess.CalledProcessError:
        print(f"Не удалось добавить существующий IP: {ip}", file=sys.stderr)

# Чтение доменов из файла
with open('list.txt', 'r') as f:
    domains = set(line.strip() for line in f)

# Запуск tcpdump в фоновом режиме
tcpdump_command = ['tcpdump', '-l', '-n', '-i', 'eth1', 'udp', 'port', '53']
tcpdump_process = subprocess.Popen(tcpdump_command, 
                                   stdout=subprocess.PIPE, 
                                   stderr=subprocess.PIPE, 
                                   universal_newlines=True, 
                                   bufsize=1)

# Регулярное выражение для извлечения доменов и IP-адресов
pattern = re.compile(r'(?:A\?|CNAME) ([^ ,]+)|\s+A\s+([\d.]+)')
current_domain = None

try:
    while True:
        line = tcpdump_process.stdout.readline()
        if not line:
            break
        print(f"Получена строка: {line.strip()}", file=sys.stderr)
        matches = pattern.findall(line)
        for match in matches:
            domain, ip = match
            if domain:
                if any(d in domain for d in domains):
                    current_domain = domain
                    print(f"Найден запрос или CNAME для домена из списка: {domain}", file=sys.stderr)
            elif ip and current_domain:
                print(f"Найден IP-адрес для {current_domain}: {ip}", file=sys.stderr)
                add_ip(ip, ip_list, 'ip_list.txt')
        if '.53 > ' in line and not any(match[1] for match in matches):
            current_domain = None
except KeyboardInterrupt:
    print("Скрипт остановлен пользователем.")
finally:
    tcpdump_process.terminate()
    print("Скрипт завершен.")