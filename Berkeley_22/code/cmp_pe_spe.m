% compare percentage error with symmetric percentage error
x = 0:1:500;
smape = (x-100)./(x+100)*2;
figure;
plot((x-100), smape*100, LineWidth = 1);
hold on
%plot([-100,100],[-100,100], LineWidth = 1);
xlabel('Percentage Error (%)');
ylabel('Symmetric Percentage Error (%)');
grid on
axis equal
set(gcf, 'Position', [0,0,400,300])
xlim([-100,400]);
ylim([-200, 150]);