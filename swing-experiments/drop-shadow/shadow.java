import javax.swing.*;
import java.awt.*;
import java.awt.geom.AffineTransform;
class MyP extends JPanel {
  public Consumer<Graphics2D> di;
  public void paintComponent(Graphics g) {
      if(di != null) di.accept((Graphics2D)g);
  }
}
var f = new JFrame("HI");
var mp = new MyP();
f.setContentPane(mp);
f.setSize(640,480);
f.setVisible(true);
mp.di = (g) -> {
   var x = mp.getWidth();
   var y = mp.getHeight();
   var img = mp.getGraphicsConfiguration().createCompatibleImage(x,y,Transparency.TRANSLUCENT);
   var g2 = (Graphics2D)img.getGraphics();
   g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
   g2.scale(x/100.0,y/100.0);

   g2.setColor(Color.BLUE);
   for(int i = 1; i < 45; i+= 3) {
      g2.drawOval(5,50-i,90,i*2);
      g2.drawOval(50-i,5,i*2,90);
   }
   g2.dispose();

   // now blur...
   float[] matrix = new float[36];
   for (int i = 0; i < 36; i++)  matrix[i] = 1.0f/36.0f;
   var blur = new java.awt.image.ConvolveOp( new java.awt.image.Kernel(6, 6, matrix), java.awt.image.ConvolveOp.EDGE_ZERO_FILL, null );
   var blurred = blur.filter(img, null);
   g2 = (Graphics2D)blurred.getGraphics();
   g2.setColor(Color.BLACK);
   g2.setComposite(AlphaComposite.SrcIn);
   g2.fillRect(0,0,x,y);
   g2.dispose();

   // now paint the background, shadow, and image
   g.setColor(mp.getBackground());
   g.fillRect(0,0,x,y);
   g.drawImage(blurred,x/100,y/100,null);
   g.drawImage(img,0,0,null);
};
