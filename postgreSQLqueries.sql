------------------------------------------------------
-- SQL and PL/pgSQL 



-- Q1:
DROP VIEW IF EXISTS Q1 CASCADE;
CREATE VIEW Q1(code) as
select distinct s.code
from subjects s
where s.longname like '%Database%'
and 'School of Computer Science and Engineering'=
(select o.longname from orgunits o where o.id=s.offeredby)
;

-- Q2:
DROP VIEW IF EXISTS Q2 CASCADE;
CREATE VIEW Q2(id) as
select distinct c.course from classes c
where 'Laboratory'=(select ct.name from class_types ct where ct.id=c.ctype)
and 'MB-G4' = (select r.longname from rooms r where r.id=c.room);

-- Q3:
DROP VIEW IF EXISTS Q3 CASCADE;
CREATE VIEW Q3(name) as
select distinct p.name from people p
where p.id in (select s.id from students s
where s.id in (select ce.student from course_enrolments ce
where ce.mark>=95 and ce.course in 
(select c.id from courses c where c.subject in
(select sj.id from subjects sj where sj.code='COMP3311'))));

-- Q4:
DROP VIEW IF EXISTS Q4 CASCADE;
CREATE VIEW Q4(code) as
select sj.code from subjects sj
where sj.code like 'COMM%'
and sj.id in
(select c.subject from courses c
where c.id in
(select cs.course from classes cs
where cs.room in
(select rf.room from room_facilities rf
where rf.facility in
(select f.id from facilities f
where f.description='Student wheelchair access'))));

-- Q5:
DROP VIEW IF EXISTS Q5 CASCADE;
CREATE VIEW Q5(unswid) as
select people.unswid from people where people.id in
(
select course_enrolments.student from course_enrolments where course_enrolments.course in (select courses.id from courses where courses.subject in (select subjects.id from subjects where subjects.code like 'COMP9%'))                                                                                                                  and course_enrolments.student not in
(select course_enrolments.student from course_enrolments where
course_enrolments.course in (select courses.id from courses where courses.subject in (select subjects.id from subjects where subjects.code like 'COMP9%'))
and  course_enrolments.grade != 'HD')
)
;

-- Q6:
DROP VIEW IF EXISTS Q6 CASCADE;
CREATE VIEW Q6(code, avg_mark) as
select ss.code, round(avg(course_enrolments.mark), 2) from 
(
    select * from subjects where
    subjects.career = 'UG'
    and subjects.uoc < 6
    and subjects.offeredby in
    (select orgunits.id from orgunits
    where orgunits.longname = 'School of Civil and Environmental Engineering'
    )
) as ss
join courses on ss.id=courses.subject
join course_enrolments on courses.id=course_enrolments.course
where courses.semester in (select semesters.id from semesters where semesters.year = '2008')
and course_enrolments.mark>=50
group by ss.code
order by avg(course_enrolments.mark) desc
;

select subjects.id from subjects where
subjects.career = 'UG'
and subjects.uoc < 6
and subjects.offeredby in
(select orgunits.id from orgunits
where orgunits.longname = 'School of Civil and Environmental Engineering'
)
;

-- Q7:
DROP VIEW IF EXISTS Q7 CASCADE;
CREATE VIEW Q7(student, course) as
select course_enrolments.student, course_enrolments.course from
course_enrolments
join courses on course_enrolments.course=courses.id
join semesters on courses.semester=semesters.id and semesters.term='S1' and semesters.year='2008'
join subjects on subjects.id=courses.subject and subjects.code like 'COMP93%'
where (course_enrolments.course, course_enrolments.mark) in (select course_enrolments.course, max(course_enrolments.mark) from
course_enrolments
join courses on course_enrolments.course=courses.id
join semesters on courses.semester=semesters.id and semesters.term='S1' and semesters.year='2008'
join subjects on subjects.id=courses.subject and subjects.code like 'COMP93%' group by course_enrolments.course)
;

-- Q8:
DROP VIEW IF EXISTS Q8 CASCADE;
CREATE VIEW Q8(course_id, staffs_names) as 
select c1.course, string_agg(c1.given, ', ' order by c1.given asc) from
(
    select course_staff.course as course, people.given as given from
    course_staff join people on course_staff.staff=people.id and people.title='AProf'
    where course_staff.course in 
    (
        select course_staff.course from
        course_staff
        join people on course_staff.staff=people.id and people.title='AProf'
        group by course_staff.course
        having count(people.id)=2
    ) 
    and course_staff.course in
    (
        select course_enrolments.course from 
        course_enrolments 
        group by course_enrolments.course
        having count(course_enrolments.student) >= 650
    )
    order by people.given asc
) as c1
group by c1.course
;

-- Q9
DROP FUNCTION IF EXISTS Q9 CASCADE;
CREATE or REPLACE FUNCTION Q9(subject_code text) returns text
as $$
    declare
        result text:='';
    begin
        select string_agg(s.code, ', ' order by s.code asc) into result
        from subjects as s
        where exists (select subjects._prereq from subjects where subjects.code=subject_code and subjects._prereq like '%'||s.code||'%'); 
        if result is null then
        result:='There is no prerequisite for subject ' || subject_code || '.';
        else
        result:='The prerequisites for subject ' || subject_code || ' are ' || result ||'.';
        end if;
        return result;
    end;
$$ language plpgsql;

-- Q10
DROP FUNCTION IF EXISTS Q10 CASCADE;
CREATE or REPLACE FUNCTION Q10(subject_code text) returns text
as $$
declare
    result text:='';
begin
    with recursive codes(code, _prereq) as (
        select distinct s.code, s._prereq
        from subjects s
        where exists (select subjects._prereq from subjects where subjects.code=subject_code and subjects._prereq like '%'||s.code||'%')
        union all 
        select distinct s.code, s._prereq
        from subjects s, codes
        where codes._prereq like '%'|| s.code ||'%'
    )
    select string_agg(distinct codes.code, ', ' order by codes.code asc) into result
    from codes;

    if result is null then
    result:='There is no prerequisite for subject ' || subject_code || '.';
    else
    result:='The prerequisites for subject ' || subject_code || ' are ' || result ||'.';
    end if;
    return result;
end;
$$ language plpgsql;
