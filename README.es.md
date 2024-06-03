# porfa

Trabaja desde la línea de comandos usando lenguaje natural en lugar de buscar comandos desconocidos en internet.

Por ejemplo, di `porfa ve a mi directorio de inicio` en lugar de `cd ~`.

Documentación en idiomas no españoles:
- [Inglés](./README.md)

# Resumen

`porfa` permite usar lenguaje natural en la línea de comandos.

Intenta minimizar las dependencias y el mantenimiento requerido al:
1. Estar implementado como un script de shell
2. Depender solo de herramientas comunes de la línea de comandos

Sin embargo, tiene una dependencia _externa_ importante, que es la [API de OpenAI](https://platform.openai.com/docs/overview). Así es como convierte el lenguaje natural en algo que podemos ejecutar en la línea de comandos.

# Instalación

## Preparación

`porfa` requiere una línea de comandos similar a Unix. Por ejemplo, `bash`, `zsh`, etc.

Para comenzar, asegúrate de tener las siguientes herramientas instaladas y disponibles a través de la línea de comandos:
- `bash`: Lo más probable es que ya tengas `bash` instalado si estás usando un sistema similar a Unix. Si estás usando Windows, [aquí hay algunas instrucciones útiles](https://www.educative.io/answers/how-to-install-git-bash-in-windows)
- `curl`: Si aún no tienes `curl` instalado, [aquí hay algunas instrucciones útiles](https://everything.curl.dev/install/index.html)
- `jq`: Si aún no tienes `jq` instalado, [aquí hay algunas instrucciones útiles](https://jqlang.github.io/jq/download/)

## Obtener una Clave de API de OpenAI

`porfa` requiere tener una cuenta de OpenAI, un saldo positivo, y una clave de API.

- Para crear una cuenta de OpenAI, visita [la página de registro](https://platform.openai.com/signup)
- Para agregar crédito, visita [la página de facturación](https://platform.openai.com/settings/organization/billing/overview)
- Para generar una clave de API, visita el artículo sobre [proyectos de la plataforma de API de OpenAI](https://help.openai.com/en/articles/9186755-managing-your-work-in-the-api-platform-with-projects#h_79e86017fd) y:
    - Crea un proyecto siguiendo las instrucciones en la sección "¿Cómo creo un proyecto?"
    - Crea una cuenta de servicio siguiendo las instrucciones en la sección "¿Qué es una cuenta de servicio y en qué se diferencia de una cuenta de usuario regular?"
    - Crea una clave de API siguiendo las instrucciones en la sección "¿Cómo gestiono las claves de API dentro de los proyectos de mi organización?"
    - También se recomienda encarecidamente leer y seguir el artículo sobre [mejores prácticas para la seguridad de claves de API](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)

## Configuración de `porfa`

Instala el script principal (requiere `sudo` ya que `/usr/local/bin` generalmente está en posesión del usuario root)
```
sudo mkdir -p /usr/local/bin
sudo curl https://raw.githubusercontent.com/verespej/please/main/please.sh -o /usr/local/bin/porfa
sudo chmod +x /usr/local/bin/porfa
```

Agrega lo siguiente a la configuración de tu shell (por ejemplo, `~/.zshrc`, `~/.bashrc`, etc.)
```
# Asegurar que la ubicación del script esté en PATH
! (echo ":$PATH:" | grep -q ":/usr/local/bin:") && export PATH=$PATH:/usr/local/bin
export PLEASE_CONFIG_SHELL_TYPE="<zsh, bash, etc.>"
export PLEASE_CONFIG_OPENAI_API_KEY="<tu clave de OpenAI>"
porfa() {
  command_text=$(/usr/local/bin/porfa "$@") && {
    restricted_commands=(">" "bash" "chmod" "chown" "cp" "curl" "dd" "fdisk" "mkfs" "mv" "parted" "rm" "wget" "zsh")
    for restricted_command in "${restricted_commands[@]}"; do
      if [[ "$command_text" == *"$restricted_command"* ]]; then
        echo "MANDATO: $command_text"
        echo "ADVERTENCIA: El mandato NO se ha ejecutado. Esto se debe a que '$restricted_command' es una operación potencialmente destructiva o peligrosa. Si deseas ejecutar el comando, debes hacerlo manualmente. NO lo ejecutes a menos que entiendas completamente lo que hace."
        return 1
      fi
    done
    eval $command_text
  } || {
    echo "ERROR: La solicitud falló"
  }
}
```

Recarga la configuración del shell:
```
source <tu archivo de configuración del shell>
```

# Uso

Aquí hay un par de ejemplos de solicitudes y resultados. Ten en cuenta que el resultado puede diferir en tu computadora.

Cambiar de directorio
```
> pwd
/Users/devuser
> porfa ve a mi carpeta de Downloads
2024-06-03 13:14:34: Thinking...
2024-06-03 13:14:35: Solution: cd ~/Downloads
> pwd
/Users/devuser/Downloads
```

Buscar archivos
```
> porfa encuentra todos los archivos pdf con "test" en el nombre de forma recursiva
2024-06-03 13:20:56: Thinking...
2024-06-03 13:20:57: Solution: find . -type f -iname '*test*.pdf'
./testdir1/testfile2.pdf
./testfile1.pdf
```

Diferenciar archivos arbitrarios usando git
```
> porfa usa git para diferenciar archivos no versionados README.md y README.es.md
2024-06-03 16:32:52: Thinking...
2024-06-03 16:32:53: Solution: git diff --no-index README.md README.es.md
...
```

Redimensionar una imagen (😂 mira cómo cambió de opinión sobre cómo abordar la tarea)
```
> porfa transforma profile-photo-copy.png a 150x150
2024-06-03 15:12:46: Thinking...
2024-06-03 15:12:48: Solution: convert profile-photo-copy.png -resize 150x150 profile-photo-copy-150x150.png
(eval):1: command not found: convert
ERROR: Request failed

> porfa instala la herramienta convert
2024-06-03 15:37:01: Thinking...
2024-06-03 15:37:02: Solution: brew install imagemagick
...

> porfa transforma profile-photo-copy.png a 150x150
2024-06-03 15:39:19: Thinking...
2024-06-03 15:39:20: Solution: sips -z 150 150 profile-photo-copy.png
/Users/hakon/Downloads/profile-photo-copy.png
  /Users/hakon/Downloads/profile-photo-copy.png

> porfatransforma profile-photo-copy.png a 100x100 usando convert
2024-06-03 15:41:27: Thinking...
2024-06-03 15:41:29: Solution: convert profile-photo-copy.png -resize 100x100 profile-photo-copy-100x100.png
WARNING: The convert command is deprecated in IMv7, use "magick"

> porfa transforma profile-photo-copy.png a 100x100 usando magick
2024-06-03 15:41:48: Thinking...
2024-06-03 15:41:50: Solution: magick profile-photo-copy.png -resize 100x100 profile-photo-copy-100x100.png
```

¿Qué es este programa? (🤷 hay margen de mejora)
```
> porfa dime sobre ti mismo
2024-06-03 15:44:37: Thinking...
2024-06-03 15:44:38: Solution: echo "I am a zsh shell command expert."
COMMAND: echo "Soy un experto en comandos zsh."
WARNING: The command has NOT been executed. This is because 'zsh' is a potentially destructive or otherwise dangerous operation. If you wish to execute the command, you must do so manually. DON'T execute it unless you fully understand what it does.
```

# Preguntas de Diseño

P: ¿Por qué usar un script de shell en lugar de algo como python o node?
R: Un objetivo es minimizar la complejidad potencial de las dependencias

P: ¿Por qué usar una función de shell para la ejecución en lugar de hacer `eval` en el script de bash?
R: Por las siguientes razones:
- Un objetivo es producir comandos que funcionen si se ejecutan manualmente en la consola del usuario
- Dado que el script se ejecuta como un subshell, no puede realizar acciones que queremos que pasan en el shell principal
    - Ejemplo: Cambiar de directorio con `cd`
    - Ejemplo: Referenciar el directorio de inicio con `~`

# Ejemplos de Respuestas de Llamadas a la API de OpenAI

## Ejemplo de Respuesta Exitosa
```
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1717170785,
  "model": "gpt-4o-2024-05-13",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "echo \"hello\""
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 98,
    "completion_tokens": 4,
    "total_tokens": 102
  },
  "system_fingerprint": "fp_..."
}
```

## Ejemplo de Respuesta de Error
```
{
  "error": {
    "message": "We could not parse the JSON body of your request...",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
```

# Licencia

Consulta el archivo [LICENSE](./LICENSE.md) para conocer los derechos y limitaciones de la licencia (MIT).
