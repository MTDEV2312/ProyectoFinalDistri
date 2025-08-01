import config
import bcrypt
import os
from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_mysqldb import MySQL
import logging

app = Flask(__name__)
app.secret_key = "your_secret_key_here"  # Cambia esto por una clave secreta fuerte

# Obtener el identificador de la instancia desde variable de entorno
APP_INSTANCE = os.getenv('APP_INSTANCE', 'Unknown')

# Configuración de logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logger.info(f"Iniciando aplicación Flask - {APP_INSTANCE}")

# Configuración de la base de datos MySQL
app.config['MYSQL_HOST'] = config.Config.MYSQL_HOST
app.config['MYSQL_USER'] = config.Config.MYSQL_USER
app.config['MYSQL_PASSWORD'] = config.Config.MYSQL_PASSWORD
app.config['MYSQL_DB'] = config.Config.MYSQL_DB
app.config['MYSQL_PORT'] = config.Config.MYSQL_PORT
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'  # Para obtener resultados como diccionarios

# Inicializar la base de datos
mysql = MySQL(app)

@app.route('/')
def home():
    return redirect(url_for('login'))

@app.route('/instance-info')
def instance_info():
    """Endpoint para verificar qué instancia está respondiendo"""
    return {
        'instance': APP_INSTANCE,
        'status': 'running',
        'message': f'Respuesta desde {APP_INSTANCE}'
    }

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        correo = request.form.get('username', '').strip()
        password = request.form.get('password', '').encode('utf-8')
        
        if not correo or not password:
            flash('Por favor ingrese ambos campos', 'danger')
            return render_template('auth/login.html')
        
        try:
            cur = mysql.connection.cursor()
            logger.debug(f"Buscando usuario: {correo}")
            cur.execute("SELECT id, contrasenia, correo FROM usuarios WHERE correo = %s", (correo,))
            user = cur.fetchone()
            cur.close()
            
            if user:
                stored_password = user['contrasenia'].encode('utf-8')
                logger.debug(f"Contraseña almacenada: {stored_password}")
                
                if bcrypt.checkpw(password, stored_password):
                    session['usuario'] = {
                        'id': user['id'],
                        'correo': user['correo']
                    }
                    logger.info(f"Usuario {user['correo']} ha iniciado sesión")
                    return redirect(url_for('dashboard'))
                else:
                    logger.warning("Contraseña incorrecta")
                    flash('Usuario o contraseña incorrectos', 'danger')
            else:
                logger.warning("Usuario no encontrado")
                flash('Usuario o contraseña incorrectos', 'danger')
                
        except Exception as e:
            logger.error(f"Error en login: {str(e)}")
            flash('Error al procesar el inicio de sesión', 'danger')

    return render_template('login.html')

@app.route('/logout')
def logout():
    if 'usuario' in session:
        logger.info(f"Usuario {session['usuario']['correo']} ha cerrado sesión")
        session.pop('usuario', None)
    return redirect(url_for('login'))

@app.route('/dashboard')
def dashboard():
    if 'usuario' not in session:
        logger.warning("Intento de acceso no autorizado al dashboard")
        return redirect(url_for('login'))

    try:
        # Obtener estadísticas para el dashboard
        cur = mysql.connection.cursor()
        
        # Productos totales
        cur.execute("SELECT COUNT(*) as total FROM productos")
        total_productos = cur.fetchone()['total']
        
        # Productos disponibles
        cur.execute("SELECT COUNT(*) as disponibles FROM productos WHERE stock > 10")
        disponibles = cur.fetchone()['disponibles']
        
        # Productos bajo stock
        cur.execute("SELECT COUNT(*) as bajo_stock FROM productos WHERE stock <= 10 AND stock > 0")
        bajo_stock = cur.fetchone()['bajo_stock']
        
        # Productos agotados
        cur.execute("SELECT COUNT(*) as agotados FROM productos WHERE stock = 0")
        agotados = cur.fetchone()['agotados']
        
        # Últimos productos agregados
        cur.execute("""
            SELECT p.*, c.nombre as categoria 
            FROM productos p
            LEFT JOIN categorias c ON p.categoria_id = c.id
            ORDER BY p.fecha_creacion DESC LIMIT 5
        """)
        ultimos_productos = cur.fetchall()
        
        cur.close()
        
        return render_template('dashboard.html', 
                             active_page='dashboard',
                             total_productos=total_productos,
                             disponibles=disponibles,
                             bajo_stock=bajo_stock,
                             agotados=agotados,
                             ultimos_productos=ultimos_productos,
                             app_instance=APP_INSTANCE)
        
    except Exception as e:
        logger.error(f"Error al cargar dashboard: {str(e)}")
        flash('Error al cargar el dashboard', 'danger')
        return render_template('dashboard.html', active_page='dashboard')

@app.route('/productos')
def productos():
    if 'usuario' not in session:
        return redirect(url_for('login'))
    
    try:
        cur = mysql.connection.cursor()
        cur.execute("""
            SELECT p.*, c.nombre as categoria_nombre 
            FROM productos p
            JOIN categorias c ON p.categoria_id = c.id
            ORDER BY p.nombre
        """)
        productos = cur.fetchall()
        cur.close()
        
        return render_template('productos/listar.html', 
                            active_page='productos',
                            productos=productos)
        
    except Exception as e:
        logger.error(f"Error al listar productos: {str(e)}")
        flash('Error al cargar la lista de productos', 'danger')
        return render_template('productos/listar.html', 
                            active_page='productos',
                            productos=[])

@app.route('/productos/nuevo', methods=['GET', 'POST'])
def nuevo_producto():
    if 'usuario' not in session:
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        try:
            nombre = request.form.get('nombre', '').strip()
            descripcion = request.form.get('descripcion', '').strip()
            precio = float(request.form.get('precio', 0))
            stock = int(request.form.get('stock', 0))
            categoria_id = int(request.form.get('categoria_id', 0))
            
            if not nombre or not descripcion or precio <= 0:
                flash('Por favor complete todos los campos requeridos', 'warning')
                return redirect(url_for('nuevo_producto'))
                
            cur = mysql.connection.cursor()
            cur.execute("""
                INSERT INTO productos 
                (nombre, descripcion, precio, stock, categoria_id)
                VALUES (%s, %s, %s, %s, %s)
            """, (nombre, descripcion, precio, stock, categoria_id))
            mysql.connection.commit()
            cur.close()
            
            logger.info(f"Nuevo producto creado por {session['usuario']['correo']}")
            flash('Producto creado exitosamente', 'success')
            return redirect(url_for('productos'))
            
        except Exception as e:
            logger.error(f"Error al crear producto: {str(e)}")
            flash('Error al crear el producto', 'danger')
    
    # Obtener categorías para el formulario
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, nombre FROM categorias ORDER BY nombre")
        categorias = cur.fetchall()
        cur.close()
    except Exception as e:
        logger.error(f"Error al obtener categorías: {str(e)}")
        categorias = []
    
    return render_template('productos/nuevo.html', 
                         active_page='nuevo-producto',
                         categorias=categorias)

@app.route('/productos/editar/<int:id>', methods=['GET'])
def editar_producto(id):
    if 'usuario' not in session:
        logger.warning("Intento de edición no autorizado")
        flash('Debe iniciar sesión para realizar esta acción', 'danger')
        return redirect(url_for('login'))

    try:
        # Obtener el producto a editar
        cur = mysql.connection.cursor()
        cur.execute("""
            SELECT p.*, c.nombre as categoria_nombre 
            FROM productos p
            LEFT JOIN categorias c ON p.categoria_id = c.id
            WHERE p.id = %s
        """, (id,))
        producto = cur.fetchone()

        if not producto:
            flash('El producto no existe', 'danger')
            return redirect(url_for('productos'))

        # Obtener todas las categorías para el select
        cur.execute("SELECT id, nombre FROM categorias ORDER BY nombre")
        categorias = cur.fetchall()
        cur.close()

        return render_template('productos/editar.html',
                            active_page='productos',
                            producto=producto,
                            categorias=categorias)

    except Exception as e:
        logger.error(f"Error al cargar formulario de edición para producto {id}: {str(e)}")
        flash('Error al cargar el formulario de edición', 'danger')
        return redirect(url_for('productos'))
    finally:
        if 'cur' in locals():
            cur.close()


@app.route('/productos/actualizar/<int:id>', methods=['POST'])
def actualizar_producto(id):
    if 'usuario' not in session:
        return redirect(url_for('login'))

    try:
        # Obtener datos del formulario
        nombre = request.form.get('nombre', '').strip()
        descripcion = request.form.get('descripcion', '').strip()
        precio = float(request.form.get('precio', 0))
        stock = int(request.form.get('stock', 0))
        categoria_id = int(request.form.get('categoria_id', 0))

        # Validaciones básicas
        if not nombre or not descripcion or precio <= 0 or stock < 0:
            flash('Por favor complete todos los campos correctamente', 'warning')
            return redirect(url_for('editar_producto', id=id))

        cur = mysql.connection.cursor()
        
        # Verificar si el nombre ya existe (excluyendo el producto actual)
        cur.execute("SELECT id FROM productos WHERE nombre = %s AND id != %s", (nombre, id))
        if cur.fetchone():
            flash('Ya existe un producto con ese nombre', 'danger')
            return redirect(url_for('editar_producto', id=id))

        # Actualizar el producto
        cur.execute("""
            UPDATE productos 
            SET nombre = %s, 
                descripcion = %s, 
                precio = %s, 
                stock = %s, 
                categoria_id = %s
            WHERE id = %s
        """, (nombre, descripcion, precio, stock, categoria_id, id))
        
        mysql.connection.commit()
        cur.close()
        
        flash('Producto actualizado exitosamente', 'success')
        return redirect(url_for('productos'))

    except ValueError:
        flash('Por favor ingrese valores válidos en los campos numéricos', 'danger')
        return redirect(url_for('editar_producto', id=id))
    except Exception as e:
        logger.error(f"Error al actualizar producto {id}: {str(e)}")
        flash('Error al actualizar el producto', 'danger')
        return redirect(url_for('editar_producto', id=id))
    finally:
        if 'cur' in locals():
            cur.close()


@app.route('/productos/eliminar/<int:id>', methods=['POST'])
def eliminar_producto(id):
    if 'usuario' not in session:
        logger.warning("Intento de eliminación no autorizado")
        flash('Debe iniciar sesión para realizar esta acción', 'danger')
        return redirect(url_for('login'))

    try:
        cur = mysql.connection.cursor()
        
        # Primero verificamos que el producto exista
        cur.execute("SELECT nombre FROM productos WHERE id = %s", (id,))
        producto = cur.fetchone()
        
        if not producto:
            flash('El producto no existe', 'danger')
            return redirect(url_for('productos'))
        
        # Luego procedemos a eliminar
        cur.execute("DELETE FROM productos WHERE id = %s", (id,))
        mysql.connection.commit()
        cur.close()
        
        logger.info(f"Producto {id} eliminado por {session['usuario'].get('correo', 'usuario desconocido')}")
        flash(f'Producto "{producto["nombre"]}" eliminado correctamente', 'success')
        
    except mysql.connection.IntegrityError as ie:
        logger.error(f"Error de integridad al eliminar producto {id}: {str(ie)}")
        flash('No se puede eliminar el producto porque tiene registros relacionados', 'danger')
    except Exception as e:
        logger.error(f"Error al eliminar producto {id}: {str(e)}")
        flash('Error al eliminar el producto', 'danger')
    finally:
        if 'cur' in locals():
            cur.close()
    
    return redirect(url_for('productos'))

@app.route('/categorias')
def categorias():
    if 'usuario' not in session:
        return redirect(url_for('login'))
    
    try:
        cur = mysql.connection.cursor()
        cur.execute("""
            SELECT c.*, COUNT(p.id) as total_productos
            FROM categorias c
            LEFT JOIN productos p ON c.id = p.categoria_id
            GROUP BY c.id
            ORDER BY c.id
        """)
        categorias = cur.fetchall()
        cur.close()
        
        return render_template('categorias/listar.html', 
                            active_page='categorias',
                            categorias=categorias)
        
    except Exception as e:
        logger.error(f"Error al listar categorías: {str(e)}")
        flash('Error al cargar la lista de categorías', 'danger')
        return render_template('categorias/listar.html', 
                            active_page='categorias',
                            categorias=[])
    

# Ruta para registro de usuarios (opcional, solo para desarrollo)
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        correo = request.form.get('email', '').strip()
        password = request.form.get('password', '').encode('utf-8')

        if not correo or not password:
            flash('Por favor complete todos los campos', 'danger')
            return render_template('/register.html')
        
        try:
            # Generar hash de la contraseña
            hashed = bcrypt.hashpw(password, bcrypt.gensalt())
            
            cur = mysql.connection.cursor()
            cur.execute("""
                INSERT INTO usuarios (correo, contrasenia) 
                VALUES (%s, %s)
            """, (correo, hashed.decode('utf-8')))
            mysql.connection.commit()
            cur.close()
            
            logger.info(f"Nuevo usuario registrado: {correo}")
            flash('Usuario registrado exitosamente', 'success')
            return redirect(url_for('login'))
            
        except Exception as e:
            logger.error(f"Error al registrar usuario: {str(e)}")
            flash('Error al registrar usuario. El correo ya existe.', 'danger')
            
    return render_template('/register.html')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)