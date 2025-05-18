import random
import string
import webbrowser

def generar_codigo_aleatorio(min_long=5, max_long=7):
    longitud = random.randint(min_long, max_long)
    caracteres = string.ascii_letters + string.digits
    return ''.join(random.choices(caracteres, k=longitud))

def abrir_pagina_scrnsc():
    codigo = generar_codigo_aleatorio()
    #url = f"https://prnt.sc/{codigo}"
    url = f"https://lightshotlows.vercel.app/generator"
    print(f"Abriendo: {url}")
    webbrowser.open(url)

# Ejecutar función
for x in range(40):
    abrir_pagina_scrnsc()
