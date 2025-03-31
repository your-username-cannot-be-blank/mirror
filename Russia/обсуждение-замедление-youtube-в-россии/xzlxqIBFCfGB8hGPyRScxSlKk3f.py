import ipaddress
import json

input_file = 'goog.json'
output_file = 'routes.txt'

gateway = '' # Адрес шлюза
interface = 'Wireguard0' # Имя интерфейса
description = 'Google' # Описание
auto = True # Добавлять автоматически
exclusive = False # Эксклюзивный маршрут

if not(gateway or interface):
    print('Нужно указать шлюз и/или интерфейс')
    exit()

def prefix_to_route(prefix):
    network = ipaddress.IPv4Network(prefix)
    ip = network.network_address
    mask = network.netmask
    result = f'ip route {ip} {mask}'
    result += ' ' + gateway if gateway else ''
    result += ' ' + interface if interface else ''
    result += ' auto' if auto else ''
    result += ' reject' if auto and exclusive else ''
    result += ' !' + description if description else ''
    return result

with open(input_file) as f:
    data_json = json.load(f)

data = [item['ipv4Prefix'] for item in data_json['prefixes'] if 'ipv4Prefix' in item]
routes = [prefix_to_route(prefix) for prefix in data]

with open(output_file, 'w') as f:
    for route in routes:
        f.write(route + '\n')
