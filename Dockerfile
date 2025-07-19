# Usa una imagen oficial de Python
FROM python:3.10

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos del proyecto
COPY . .

# Instala las dependencias
RUN apt-get update && apt-get install -y gcc 
RUN pip install Flask==2.3.2
RUN pip install Flask-MySQLdb==1.0.1
RUN pip install bcrypt

# Expone el puerto por donde Flask corre
EXPOSE 5000

# Comando para ejecutar la app
CMD ["python", "app.py"]
