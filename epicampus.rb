


name=['Robinson','Diego_Alonso','Luz_Ofelia ','Deisy_Liliana','Yuliana_Andrea','Alejandra_Maria','Jair_Arledy','Juan_Carlos','Jose_David','Esteban','Luz_Marina','Edison_Alonso','Daniela','Edison_Arbey','Monica_Maria','Diana_Marcela','Leidy_Johana' ,'Juan_Felipe','Ana_Maria','Maria_Eugenia','Esteban','Anselmo_Vianney','Maria_Natali','Alejandro' ,'Julian_David','Evelin_Juliet','Sebastian','Diego_Alejandro','Maria_clemencia']

name3=['Robinson','Diego_Alonso','Luz_Ofelia ','Deisy_Liliana','Yuliana_Andrea','Hector_Ivan','Alejandra_Maria','Jair_Arledy','Juan_Carlos','Jose_David','Esteban','Luz_Marina','Edison_Alonso','Daniela','Edison_Arbey','Monica_Maria','Diana_Marcela','Leidy_Johana' ,'Juan_Felipe','Ana_Maria','Maria_Eugenia','Esteban','Anselmo_Vianney','Maria_Natali','Alejandro' ,'Julian_David','Evelin_Juliet','Sebastian','Diego_Alejandro','Maria_clemencia']

lastname=['Guerra_Osorio','Montoya_Restrepo','Ruiz_Zapata','Mosquera_Giraldo','Padierna_Jaramillo','Ramirez_Blandon','Garcia_Patino','Munoz_Cano','Jaramillo_Velasquez','Caro_Caro','Fernandez_Jaramillo','Agudelo_Echavarria','Sanudo_Gomez','Florez_Londono','Llano_Arango','Metaute_Aguirre','Lopez_Zuluaga','Jaramillo_Uribe','Salazar_alvarez','Tejada_Zabaleta','Gaviria_Gallego','Tamayo_Corrales','Bedoya_Avendano','Cadavid_Monsalve ','Hernandez_Gil','Boder_Zaluaga','Perez_Zapata','Posada Grisales','Vallejo_Restrepo']


lastname=['Guerra_Osorio','Montoya_Restrepo','Ruiz_Zapata','Mosquera_Giraldo','Padierna_Jaramillo','Botero_Jaramillo','Ramirez_Blandon','Garcia_Patino','Munoz_Cano','Jaramillo_Velasquez','Caro_Caro','Fernandez_Jaramillo','Agudelo_Echavarria','Sanudo_Gomez','Florez_Londono','Llano_Arango','Metaute_Aguirre','Lopez_Zuluaga','Jaramillo_Uribe','Salazar_alvarez','Tejada_Zabaleta','Gaviria_Gallego','Tamayo_Corrales','Bedoya_Avendano','Cadavid_Monsalve ','Hernandez_Gil','Boder_Zaluaga','Perez_Zapata','Posada Grisales','Vallejo_Restrepo']

id=['CC1036399544','CC70564172','CC43673712','CC35604585','CC1128471081','CC70630676','CC43220818','CC98569203','CC98497090','TI1000410293','TI96070216202','CC39166905','CC98530070','TI93061203735','CC71333318','CC43721277','CC32142881','CC39457771','CC8125294','TI95062613514','CC30575859','CC1128466630','CC70855022','CC1035418670','CC8359136','TI1192757957','CC1017166811','TI99012404120','CC3378558','CC32295354']

id=['CC1036399544','CC70564172','CC43673712','CC35604585','CC1128471081','CC43220818','CC98569203','CC98497090','TI1000410293','TI96070216202','CC39166905','CC98530070','TI93061203735','CC71333318','CC43721277','CC32142881','CC39457771','CC8125294','TI95062613514','CC30575859','CC1128466630','CC70855022','CC1035418670','CC8359136','TI1192757957','CC1017166811','TI99012404120','CC3378558','CC32295354']


birthdate=['23.05.1994','21.03.1965','18.04.1968','22.03.1978','15.10.1988','3.03.1978 ','16.12.1972','30.08.1967','16.11.1999','2.07.1996 ','4.08.1962 ','24.04.1970','12.06.1993','14.05.1978','10.12.1968','28.08.1979','11.01.1986','07.04.1981','26.06.1995','9.09.1974 ','16.10.1987','6.10.1977 ','16.02.1988','16.06.1984','31.01.2001','1.11.1988 ','24.01.1999','15.07.1980','25.10.1983']

birthdate=['23.05.1994','21.03.1965','18.04.1968','22.03.1978','15.10.1988','2.18.1963 ','3.03.1978 ','16.12.1972','30.08.1967','16.11.1999','2.07.1996 ','4.08.1962 ','24.04.1970','12.06.1993','14.05.1978','10.12.1968','28.08.1979','11.01.1986','07.04.1981','26.06.1995','9.09.1974 ','16.10.1987','6.10.1977 ','16.02.1988','16.06.1984','31.01.2001','1.11.1988 ','24.01.1999','15.07.1980','25.10.1983']


cod15=['S01','S02','S03','S04','S05','S13','S06','S07','S08','S09','S10','S11','S12','S14','S15','S16','S17','S18','S19','S20','S21','S22','S23','S24','S25','S26','S27','S28','S29','S30']

cod3=['S32','S40','S34','S35','S55','S54','S45','S60','S51','S33','S38','S58','S42','S41','S47','S46','S56','S59','S48','S53','S52','S37','S31','S49','S50','S43','S44','S36','S39','S57']

num=(0..28)
num3=(0..29)

File.open("epicampus.txt", 'w') do |file|
  file << "codigo\tVol_hipo_izquierdo\tvol_hipo_derecho\n"
end

num.each do |d|

`/Users/catalinabustamante/codigo/rubycampus/rubycamppus.rb -f /Users/catalinabustamante/Desktop/P#{d}/dicom  -o /Users/catalinabustamante/Desktop/P#{d}/output -d axial -s #{name[d]},#{lastname[d]},#{id[d]},#{birthdate[d]},1.5#{cod15[d]}`

end


