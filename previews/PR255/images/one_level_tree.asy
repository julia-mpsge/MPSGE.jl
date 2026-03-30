size(780,750);

pair root = (0,0);

real radius = .125;

real level = -4*radius;

string[] node_names = {"$n_1$","$n_2$","$n_{k-1}$","$n_k$"};


for(int i=0;i<4; ++i){
    pair p = ((-3 + 2*i)*2*radius, level);
    draw(root -- p);
    fill(circle(p,radius),white);
    draw(circle(p,radius));
    label(node_names[i],p,fontsize(300));
}

fill(circle(root,radius),white);
draw(circle(root,radius));

label("$n$",root, fontsize(300));

label("$\dots$", (0,level), fontsize(300));

//dot((0,level),fontsize(300));