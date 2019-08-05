
import java.awt.Component;
import java.awt.Font;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;
import javax.swing.event.ListDataListener;
import javax.swing.*;

class PricePoint {
  public double price;
  public int shares;
  public double pnl;
  public String toString() { 
    return String.format("% 4d   %7.2f   %7.2f",shares, price, pnl);
  }
}

class PriceLadderCellRenderer extends JLabel implements ListCellRenderer<PricePoint> {
   PriceLadderCellRenderer() {
      super();
      setFont(new Font(Font.MONOSPACED, Font.PLAIN, 14));
      setOpaque(true); // so that the background is drawn
   }
   public Component getListCellRendererComponent(
      JList<? extends PricePoint> list,
      PricePoint value, 
      int index,
      boolean isSelected,
      boolean cellHasFocus) {
       setText(value.toString());
       if(index < 50) {
          setBackground(java.awt.Color.RED);
       } else {
          setBackground(java.awt.Color.GREEN);
       }
       return this;
   }
}

class VirtualListModel implements ListModel<PricePoint> {

  private final double highPrice;
  private final int size;
  private final double tick;
  PricePoint result;

  VirtualListModel(double center, int rows, double unit) {
      highPrice = center + (rows/2)*unit; 
      tick = unit;
      size = rows;
      result = new PricePoint();
  }

  public void addListDataListener(ListDataListener l) { }
  public void removeListDataListener(ListDataListener l) { } 

  public PricePoint getElementAt(int index) {
      result.price = highPrice - index*tick; 
      result.shares = 0;
      result.pnl = 0;
      //System.out.printf("data request for %d\n", index);
      return result;
  }

  public int getSize() { return size; }
}


class ClickListener implements MouseListener {
  private final JList<PricePoint> parent;

  ClickListener(JList<PricePoint> l) {
      parent = l;
  } 

  public void	mouseClicked(MouseEvent e)	 {
      int index = parent.locationToIndex(e.getPoint());
      double price = parent.getModel().getElementAt(index).price;

      if(SwingUtilities.isLeftMouseButton(e)) {
         System.out.printf("LEFT on %7.2f\n", price);
      } else if(SwingUtilities.isRightMouseButton(e)) {
         System.out.printf("RIGHT on %7.2f\n", price);
      } else {
         System.out.printf("Some other button %d!\n", e.getButton());
      }
  }

  public void	mouseEntered(MouseEvent e)	{  }
  public void	mouseExited(MouseEvent e)  { }	
  public void	mousePressed(MouseEvent e)	{ }
  public void	mouseReleased(MouseEvent e)	 { }
}

public class cmd extends JFrame {
  public cmd() {
    super("Virtual List Example");
    setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
    var lst = new JList<PricePoint>(new VirtualListModel(2500.00, 200, 0.25));
    lst.setCellRenderer(new PriceLadderCellRenderer());
    lst.setVisibleRowCount(25);    
    lst.addMouseListener(new ClickListener(lst)); 

    final var proto = new PricePoint();
    proto.shares = -99999;
    proto.pnl = -222009;
    proto.price = 11122009.25;
    lst.setPrototypeCellValue(proto);
    setContentPane(new JScrollPane(lst));
    pack();
    setVisible(true);
  }

  public static void main(String[] args) {
    new cmd();
  }
}
