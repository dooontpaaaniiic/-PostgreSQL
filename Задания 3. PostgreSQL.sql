/*Задание 1. Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
•	Пронумеруйте все платежи от 1 до N по дате
•	Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
•	Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка 
должна быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
•	Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к 
меньшим так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.*/

select 
	payment_date as Дата_платежа,
	row_number () over(order by payment_date) as Номер_платежа, 
	customer_id as Айди_покупателя, 
	row_number() over(partition by customer_id) as Номер_платежа_покупателя, 
	amount as Сумма_платежа, 
	dense_rank() over (partition by customer_id order by amount desc) as Номер_платежа_по_стоимости, 
	sum(amount) over(partition by customer_id order by payment_date, amount rows unbounded preceding) as Нарастающий_итог 
from payment p
order by payment_date, amount ;

/*Задание 2. С помощью оконной функции выведите для каждого покупателя стоимость платежа и 
стоимость платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.*/

select 
	payment_date as Дата_платежа,
	customer_id as Айди_покупателя,
	lag(amount,1,0.0) over (partition by payment_date order by customer_id) as Предыдущий_платеж,
	amount as Платеж
from payment p;

/*Задание 3. С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.*/
select 
	payment_date as Дата_платежа,
	customer_id as Айди_покупателя,
	amount as Платеж,
	lead(amount,1,0.0) over (partition by customer_id) as Следующий_платеж,
	(case when (amount - lead(amount,1,0.0) over (partition by customer_id)) > 0 
		then 'Больше на ' || cast((amount-lead(amount,1,0.0) over (partition by customer_id)) as int)  
		else 'Меньше на ' || cast(abs(amount - (lead(amount,1,0.0) over (partition by customer_id))) as int)  end) as Разница_платежей
from payment p;

/*Задание 4. С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.*/
with Последний_платеж as (
  select *,
  last_value(payment_date) over (partition by customer_id order by payment_date) as Последний_платеж
  from payment
)
select *
from Последний_платеж
where Последний_платеж = payment_date;

/*Задание 5. С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года с 
нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) с сортировкой по дате.*/
select
    staff_id as Айди_работника,
    date(payment_date) as Дата,
    sum(amount) over (partition by staff_id  order by payment_date, amount rows unbounded preceding) as Нарастающий_итог_по_сотруднику,
    sum(amount) over (partition by staff_id order by payment_date, amount rows between unbounded preceding and unbounded following) as Сумма_продаж_за_август_2005,
    sum(amount) over (partition by staff_id, DATE(payment_date) order by payment_date, amount rows unbounded preceding) as Нарастающий_итог_по_дате,
    sum(amount) over (partition by staff_id, DATE(payment_date)) as Сумма_по_дням
from payment p
where payment_date between '2005-08-01' and '2005-08-31'
order by staff_id, date(payment_date);

/*Задание 6. 20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа 
получал дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей, 
которые в день проведения акции получили скидку. */
with Подсчет_победителей as (
select
	*,
	row_number () over (order by date(payment_date)) as Номер_покупателя
	from payment p
	where date(payment_date) = '2005-08-20'
)
select
	date(payment_date) as Дата,
	Номер_покупателя,
	customer_id as Айди_покупателя
from Подсчет_победителей
where Номер_покупателя % 100 = 0;

/*Задание 7. Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
•	покупатель, арендовавший наибольшее количество фильмов;
•	покупатель, арендовавший фильмов на самую большую сумму;
•	покупатель, который последним арендовал фильм.*/
with RankedCustomers as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c3.country,
        count(p.payment_id) over (partition by c.customer_id) as num_rentals,
        sum(p.amount) over (partition by c.customer_id) as total_amount,
        row_number() over (partition by c.customer_id order by p.payment_date desc) as rental_order,
        p.payment_date
    from customer c
    inner join payment p on p.customer_id = c.customer_id
    inner join rental r on r.rental_id = p.rental_id
    inner join address a on a.address_id = c.address_id
    inner join city c2 on c2.city_id = a.city_id
    inner join country c3 on c3.country_id = c2.country_id
),
MaxRentals as (
    select
        country,
        max(num_rentals) as max_num_rentals,
        max(total_amount) as max_total_amount,
        max(payment_date) as max_payment_date
    from RankedCustomers
    group by country
)
select
    rc.country,
    rc.customer_id,
    rc.first_name,
    rc.last_name,
    rc.num_rentals,
    rc.total_amount,
    case
        when rc.num_rentals = mr.max_num_rentals then rc.num_rentals
        else null
    end AS customer_with_most_rentals,
    case 
    	when rc.payment_date = mr.max_payment_date then rc.payment_date
    	else null
    end as customer_last_rental,    
    case
        when rc.total_amount = mr.max_total_amount THEN rc.total_amount
        else null
    end as customer_with_highest_amount
from RankedCustomers rc
join MaxRentals mr on rc.country = mr.country
where rc.rental_order = 1 and (rc.num_rentals = mr.max_num_rentals or rc.payment_date = mr.max_payment_date or rc.total_amount = mr.max_total_amount)
order by rc.country, rc.rental_order desc;
