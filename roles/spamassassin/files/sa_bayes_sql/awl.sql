CREATE TABLE IF NOT EXISTS awl (
    username varchar(100) NOT NULL,
    email varchar(200) NOT NULL,
    ip varchar(16) NOT NULL,
    count int(11) default '0',
    totscore float default '0',
    PRIMARY KEY  (username,email,ip)
);
