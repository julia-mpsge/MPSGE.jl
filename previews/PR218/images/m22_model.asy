settings.outformat="png"; 
settings.render=8;

size(400,400);


picture X;
size(X,100,100);

real M = 40;

label(X,"X", (0*M,0*M));
label(X,"t=0", (0,0),1.5N);
label(X,"s=$\sigma$", (0,0),1.5S);

label(X,"PX, 120", (0*M,1*M));
label(X,"PY, 20", (-1*M,-1*M));

label(X,"va=1", (1*M,-1*M));
label(X,"PL, 40", (0*M,-2*M));
label(X,"CONS $\Rightarrow$ tax", (0*M,-2*M),1.5S);

label(X,"PK, 60", (2*M,-2*M));
label(X,"CONS $\Rightarrow$ tax", (2*M,-2*M),1.5S);

real mar = 4;

draw(X,(0*M,0*M) -- (0*M,1*M), Arrow, Margin(mar,mar-2)); 
draw(X,(-1*M,-1*M) -- (0*M,0*M),Arrow, Margin(mar,mar+1)); 
draw(X,(1*M,-1*M) -- (0*M,0*M),Arrow, Margin(mar,mar+1)); 
draw(X,(0*M,-2*M) -- (1*M,-1*M),Arrow, Margin(mar,mar)); 
draw(X,(2*M,-2*M) -- (1*M,-1*M),Arrow, Margin(mar,mar)); 


picture Y;
size(Y,100,100);

real M = 40;

label(Y,"Y", (0*M,0*M));
label(Y,"t=0", (0,0),1.5N);
label(Y,"s=.75", (0,0),1.5S);
label(Y,"PY, 120", (0*M,1*M));
label(Y,"PX, 20", (-1*M,-1*M));

label(Y,"va=1", (1*M,-1*M));
label(Y,"PL, 60", (0*M,-2*M));
label(Y,"PK, 40", (2*M,-2*M));

real mar = 4;

draw(Y,(0*M,0*M) -- (0*M,1*M), Arrow, Margin(mar,mar-2)); 
draw(Y,(-1*M,-1*M) -- (0*M,0*M),Arrow, Margin(mar,mar+2)); 
draw(Y,(1*M,-1*M) -- (0*M,0*M),Arrow, Margin(mar,mar+2)); 
draw(Y,(0*M,-2*M) -- (1*M,-1*M),Arrow, Margin(mar,mar)); 
draw(Y,(2*M,-2*M) -- (1*M,-1*M),Arrow, Margin(mar,mar)); 



picture W;
size(W,100,100);

real M = 40;

label(W,"W", (0*M,0*M));
label(W,"t=0", (0,0),1.5N);
label(W,"s=1", (0,0),1.5S);
label(W, "PW, 200",(0*M,1*M));
label(W,"PY, 100", (1*M,-1*M));
label(W,"PX, 100", (-1*M,-1*M));


real mar = 4;

draw(W,(0*M,0*M) -- (0*M,1*M), Arrow, Margin(mar,mar-2)); 
draw(W,(-1*M,-1*M) -- (0*M,0*M),Arrow, Margin(mar,mar+2)); 
draw(W,(1*M,-1*M) -- (0*M,0*M),Arrow, Margin(mar,mar+2)); 


picture CONS;
size(CONS,100,100);

real M = 40;

label(CONS,"CONS", (0*M,0*M));
label(CONS, "PW, 200",(0*M,-1*M));
label(CONS,"PL, 100", (1*M,1*M));
label(CONS,"PK, 100", (-1*M,1*M));


real mar = 4;

draw(CONS,(0*M,-1*M) -- (0*M,0*M), Arrow, Margin(mar,mar-1)); 
draw(CONS,(0*M,0*M)--(1*M,1*M),Arrow, Margin(mar,mar)); 
draw(CONS,(0*M,0*M) -- (-1*M,1*M),Arrow, Margin(mar,mar)); 



add(X,(0,0));
add(Y,(100,0));
add(W, (0,-75));
add(CONS, (100,-75));