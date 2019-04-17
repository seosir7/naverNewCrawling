#다운로드 및 라이브러리 불러오기
install.packages("rvest"); # html 크롤링을 위한 패키지
install.packages("dplyr"); #data.table : data.table 패키지와 사용
                           #각종 데이터베이스 : 현재 MySQL, PostgreSQL, SQLite, BigQuery를 지원
                           #데이터 큐브 : dplyr 패키지 내부에 실험적으로 내장됨 
install.packages("stringr"); # 정규 표현식을 위한 패키지

library(rvest);
library(dplyr);
library(stringr);

#검색어 및 날짜 입력기
naver_search="2018평창올림픽 강원랜드"; #검색어 입력해주세요 ex)2019 KBO
naver_date_from="2018.02.01"; #검색시작날짜 ex) 2019.05.02
naver_date_to="2018.02.28"; #검색마지막날짜 ex) 2019.05.14

# https://search.naver.com/search.naver?where=news&sm=tab_jum&query=
# 2019+kbo&nso=so%3Ar%2Cp%3Afrom20180412to20180413%2Ca%3Aall
###################################################################################################################

naver_query=gsub(pattern=" ", replacement = "%20",x=naver_search);
naver_date_from_sub=as.Date.character(naver_date_from,"%Y.%m.%d");
naver_date_to_sub=as.Date.character(naver_date_to,"%Y.%m.%d");
naver_date_from_sub=gsub(pattern="-", replacement = "",x=naver_date_from_sub);
naver_date_to_sub=gsub(pattern="-", replacement = "",x=naver_date_to_sub);

#Basic NAVER url 저장
#첫번째 페이지 url 
url_num=1;
naver_basic_url=paste0("https://search.naver.com/search.naver?&qdt=0&where=news&query=",naver_query,
                       "&sm=tab_pge&sort=2&photo=0&field=0&reporter_article=&pd=3&ds=",naver_date_from,
                       "&de=",naver_date_to,"&docid=&nso=so:da,p:from",naver_date_from_sub,"to",naver_date_to_sub,
                       ",a:all&mynews=0&start=",url_num,"&refresh_start=0");

#검색 기사 수 불러오기
html=read_html(naver_basic_url)
url_num= html %>% html_nodes('.title_desc.all_my') %>% html_nodes('span') %>% html_text();
url_num=unlist(str_extract_all(gsub("\\,", "", url_num), "\\d+"));
url_num=as.numeric(url_num[3]);
url_num; #결과값 총 기사 수 출력

#전체 Naver Url 저장
urls=NULL;
for(x in 0:as.integer(url_num/10)){
  
  urls[x+1]=paste0("https://search.naver.com/search.naver?&qdt=0&where=news&query=",naver_query,
                   "&sm=tab_pge&sort=2&photo=0&field=0&reporter_article=&pd=3&ds=",naver_date_from,
                   "&de=",naver_date_to,"&docid=&nso=so:da,p:from",naver_date_from_sub,"to",naver_date_to_sub,
                   ",a:all&mynews=0&start=",x*10+1,"&refresh_start=0");
}

#URL/헤드라인/매체/날짜기 불러오기

links=NULL;
media=NULL;
dates=NULL;
headlines=NULL;

for(url in urls){
  html=read_html(url);
  links=c(links, html %>% html_nodes('._sp_each_url') %>% html_attr('href'));
  media=c(media, html %>% html_nodes('._sp_each_source') %>% html_text());
  dates=c(dates,unlist(str_extract_all(gsub("\\,", "", html %>% html_nodes('.txt_inline') %>% html_text()), "\\d+.\\d+.\\d+")));
  headlines=c(headlines, html %>% html_nodes('._sp_each_title') %>% html_text());
}

#기사별 텍스트, 헤드라인 불러오기

news_text=c();
news_imgSrc=c();

for(i in 1:length(links)){
  if(length(grep("naver",links[i]))==1){
    html_naver=read_html(links[i]);
    
    temp_text=repair_encoding(html_text(html_nodes(html_naver,'#newsEndContents')),from='utf-8')
    temp_img = html_naver %>% html_nodes('.end_photo_org') %>% html_nodes('img') %>% html_attr('src');
    if(length(temp_text)==0){
      temp_text=repair_encoding(html_text(html_nodes(html_naver,'#articleBodyContents')),from='utf-8');
      if(length(temp_text)==0){temp_text="The text can't be extracted.";}
      if(length(temp_img)==0){temp_img="The image can't be extracted.";}
      }
  }else{
    temp_text="NULL"; #NOT NAVER NEWS FORMAT
    temp_img="NULL"; #NOT NAVER NEWS FORMAT
  }
  news_text=c(news_text,temp_text);
  news_imgSrc=c(news_imgSrc,temp_img[1]);
}

#Mapping
news=cbind(url=unlist(links),date=unlist(dates), medium=unlist(media), headline=unlist(headlines),text=unlist(news_text),imgSrc=unlist(news_imgSrc));
news=as.data.frame(news);

###################################################################################################################

#Excel 추출
write.csv(news,file="abc.csv"); #파일명 바꿔주기 EX)2018kbo온라인스크랩.csv

