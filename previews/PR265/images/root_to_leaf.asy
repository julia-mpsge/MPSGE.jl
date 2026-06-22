size(500,500);

pair root = (0,0);

real radius = .125;

real level = -4*radius;

string[] node_names = {"$n_1$","$n_2$","$n_k$","$n_{k+1}$"};

real node(int i, real r = radius){
    if (i>=2){
        return -2*(i+.25)*2*radius;
    }
    return -2*i*2*radius;
}

for(int i=0;i<3; ++i){
    pair p = (0,node(i));
    pair pp = (0,node(i+1));
    draw(p -- pp);
}

for(int i=0;i<4; ++i){
    pair p = (0,node(i));
    fill(circle(p,radius),white);
    draw(circle(p,radius));
    label(node_names[i],p,fontsize(300));
}

fill(circle((0,node(2)+.325-.01),radius/2),white);

label("$\Huge\vdots$",(0,node(2)+.325),fontsize(300));