import socket

# Список доменов для преобразования в IP и добавления в route
domains = [
    "autodesk.fi", "autodesk.de", "autodesk.es", "autodesk.ca", "autodesk.dk", "autodesk.pl",
    "ns1.autodesk.com", "ns2.autodesk.com", "ns3.autodesk.com", "a.gtld-servers.net", "b.gtld-servers.net",
    "c.gtld-servers.net", "d.gtld-servers.net", "e.gtld-servers.net", "f.gtld-servers.net", "g.gtld-servers.net",
    "h.gtld-servers.net", "i.gtld-servers.net", "j.gtld-servers.net", "k.gtld-servers.net", "l.gtld-servers.net",
    "m.gtld-servers.net", "adobeereg.com", "126114-app1.autodesk.com", "94175-app1.autodesk.com",
    "94184-app2.autodesk.com", "96579-lbal1.autodesk.com", "acamp.autodesk.com", "adeskdi3.autodesk.com",
    "adeskdmzpdc.autodesk.com", "adeskgate.autodesk.com", "adesknews2.autodesk.com", "adeskout.autodesk.com",
    "adsknateur.autodesk.com", "amernetlog.autodesk.com", "app5.autodesk.com", "aprimo-relay1.autodesk.com",
    "aprimo-relay2.autodesk.com", "aprimo-relay3.autodesk.com", "aprimo-relay4.autodesk.com",
    "autosketch.autodesk.com", "blues.autodesk.com", "cbuanprd.autodesk.com", "cbuanprhcllb.autodesk.com",
    "genuine-software2.autodesk.com", "ase-cdn-stg.autodesk.com", "ase.autodesk.com",
    "*.autodesk.com", "*.autodesk360.com", "*.akamaiedge.net", "*.appstreaming.autodesk.com", "*.api.autodesk.com",
    "accounts.autodesk.com", "appstreaming.autodesk.com", "fusionapi.autodesk.com", "notifications.api.autodesk.com",
    "ui-dls360.autodesk.com", "autodesk360.com", "amazonaws.com", "akamai.com", "akamaitechnologies.com",
    "tracepartsonline.net", "mcmaster.com", "*.s3.amazonaws.com", "*.s3-accelerate.amazonaws.com", "*.launchdarkly.com",
    "autodesk.com", "help.autodesk.com", "dl.appstreaming.autodesk.com"  # Новый домен добавлен здесь
]

# Открываем файл для записи команд
with open("route_add_commands.bat", "w") as file:
    for domain in domains:
        try:
            # Если домен содержит '*', заменим на общую часть для разрешения
            if domain.startswith("*."):
                base_domain = domain.replace("*.", "")
            else:
                base_domain = domain

            # Получаем список IP-адресов для домена
            addresses = socket.getaddrinfo(base_domain, None)
            unique_ips = {addr[4][0] for addr in addresses}  # Извлекаем уникальные IP

            # Записываем каждую команду для IP в файл
            for ip_address in unique_ips:
                file.write(f"route ADD {ip_address} MASK 255.255.255.255 0.0.0.0\n")

        except socket.gaierror:
            # Сообщение об ошибке в случае, если домен не удаётся разрешить
            file.write(f":: Не удалось разрешить домен: {domain}\n")

print("Команды сохранены в файл route_add_commands.bat")
