Создание вирутальных машин

исползует YA cloud provider для создания VM  
используемые параметры:
 - vm_count, кол-во машин, numbers, 1
 - cores
 - memory
 - disk_size
 - image_id
 - subnet_id
 - name

типы и значения по умолчанию смотри в variables.tf

модуль создает нужное количество машин заданное параметром vm_count в определенной зоне доступности
