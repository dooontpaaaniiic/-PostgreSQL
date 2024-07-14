--Задание 1. Выведите для каждого покупателя его адрес, город и страну проживания.
select 
	customer_id as Пользователь,
	a.address as Адреc,
	c2.city as Город,
	c3.country as Страна
from customer c
left join address a on a.address_id = c.address_id
left join city c2 on c2.city_id = a.city_id
left join country c3 on c3.country_id = c2.country_id;

/*Задание 2. С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
• Доработайте запрос и выведите только те магазины, у которых количество покупателей больше 300.
Для решения используйте фильтрацию по сгруппированным строкам с функцией агрегации.
• Доработайте запрос, добавив в него информацию о городе магазина, фамилии и имени продавца, 
который работает в нём.*/
--Изначальный запрос
select 
	store_id as Магазин, 
	count(*) as Количество_покупателей 
from customer c
group by c.store_id;

--Запрос без подбробного вывода данных
select 
	store_id as Магазин, 
	count(*) as Количество_покупателей 
from customer c
group by c.store_id
having count(*) > 300;

--Запрос с подбробным выводом данных
select 
	c2.city as Город_магазина, 
	s2.first_name as Имя_продавца, 
	s2.last_name as Фамилия_продавца, 
	s.store_id as Магазин,
	count(*) as Количество_покупателей 
from customer c
left join store s on s.store_id = c.store_id
left join address a on a.address_id = s.address_id
left join city c2 on c2.city_id = a.city_id
left join staff s2 on s2.store_id = s.store_id
group by c2.city, s2.first_name, s2.last_name, s.store_id
having count(*) > 300;


--Выведите топ-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов
select 
	customer_id as Покупатель, 
	count(payment_id) as Количество_аренд 
from payment p
group by customer_id
order by count(payment_id) desc limit 5;

/*Задание 4. Посчитайте для каждого покупателя 4 аналитических показателя:
• количество взятых в аренду фильмов;
• общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа);
• минимальное значение платежа за аренду фильма;
• максимальное значение платежа за аренду фильма.*/
select 
	customer_id as Покупатель,
	count(rental_id) as Количество_взятых_фильмов,
	round(sum(amount)) as Общая_стоимость_платежей,
	min(amount) as Минимальная_стоимость_платежа,
	max(amount) as Максимальная_стоимость_платежа
from payment p
group by customer_id
order by customer_id;

--Задание 5. Используя данные из таблицы городов, составьте одним запросом всевозможные пары городов так, чтобы в результате не было пар с одинаковыми названиями городов. Для решения необходимо использовать декартово произведение.
select 
	c.city as Первый_город, 
	c2.city as Второй_город 
from city c
cross join city c2 
where c.city < c2.city;

--Задание 6. Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и дате возврата (поле return_date), вычислите для каждого покупателя среднее количество дней, за которые он возвращает фильмы.
select 
	customer_id as Покупатель, 
	round(avg(date(return_date)-date(rental_date)),0) as Средняя_разница_в_днях 
from rental r 
group by customer_id 
order by customer_id;

--Задание 7. Посчитайте для каждого фильма, сколько раз его брали в аренду, а также общую стоимость аренды фильма за всё время.
select 
	f.title as Название_фильма, 
	count(r.rental_id) as Сколько_раз_брали_в_аренду,
	sum(coalesce(p.amount,0)) as Общая_стоимость_аренды 
from rental r 
left join inventory i on i.inventory_id = r.inventory_id
right join film f on f.film_id = i.film_id 
left join payment p on p.rental_id = r.rental_id 
group by f.film_id 
order by f.film_id; 


--Задание 8. Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые ни разу не брали в аренду.
select 
	f.title as Название_фильма, 
	count(r.rental_id) as Сколько_раз_брали_в_аренду 
from rental r 
left join inventory i on i.inventory_id = r.inventory_id
right join film f on f.film_id = i.film_id 
group by f.film_id
having count(r.rental_id)=0
order by f.film_id;

/*Задание 9. Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку 
 * «Премия». Если количество продаж превышает 7 300, то значение в колонке будет 
 * «Да», иначе должно быть значение «Нет».*/
select 
	s.staff_id as Продавец, 
	count(p.payment_id) as Количество_продаж, 
	(case when count(p.payment_id) > 7300 then 'Да' else 'Нет' end) as Премия_будет
from payment p 
right join staff s on s.staff_id = p.staff_id 
group by s.staff_id
order by s.staff_id;


